#import "KGORequest.h"
#import "JSON.h"
#import "KGORequestManager.h"
#import "Foundation+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"

NSString * const KGORequestErrorDomain = @"com.modolabs.KGORequest.ErrorDomain";

NSString * const KGORequestDurationPrefKey = @"KGORequestDuration";
NSString * const KGORequestLastRequestTime = @"last";

@interface KGORequest (Private)

- (void)terminateWithErrorCode:(KGORequestErrorCode)errCode userInfo:(NSDictionary *)userInfo;

- (void)runHandlerOnResult:(id)result;
- (BOOL)isUnderMinimumDuration;

@end


@implementation KGORequest

@synthesize url, module, path, getParams, postParams, cachePolicy, ifModifiedSince;
@synthesize format, delegate, timeout, minimumDuration;
@synthesize expectedResponseType, handler, result = _result;

+ (KGORequestErrorCode)internalCodeForNSError:(NSError *)error
{
	KGORequestErrorCode errCode;
	switch ([error code]) {
		case kCFURLErrorCannotConnectToHost: case kCFURLErrorCannotFindHost:
		case kCFURLErrorDNSLookupFailed: case kCFURLErrorResourceUnavailable:
			errCode = KGORequestErrorUnreachable;
			break;
		case kCFURLErrorNotConnectedToInternet: case kCFURLErrorInternationalRoamingOff: case kCFURLErrorNetworkConnectionLost:
			errCode = KGORequestErrorDeviceOffline;
			break;
		case kCFURLErrorTimedOut: case kCFURLErrorRequestBodyStreamExhausted: case kCFURLErrorDataLengthExceedsMaximum:
			errCode = KGORequestErrorTimeout;
			break;
		case kCFURLErrorBadServerResponse: case kCFURLErrorZeroByteResource: case kCFURLErrorCannotDecodeRawData:
		case kCFURLErrorCannotDecodeContentData: case kCFURLErrorCannotParseResponse: case kCFURLErrorRedirectToNonExistentLocation:
			errCode = KGORequestErrorBadResponse;
			break;
		case kCFURLErrorBadURL: case kCFURLErrorUnsupportedURL: case kCFURLErrorFileDoesNotExist: 
			errCode = KGORequestErrorBadRequest;
			break;
		case kCFURLErrorUserAuthenticationRequired:
			errCode = KGORequestErrorForbidden;
			break;
		case kCFURLErrorCancelled: case kCFURLErrorUserCancelledAuthentication: case kCFURLErrorCallIsActive:
			errCode = KGORequestErrorInterrupted;
			break;
		case kCFURLErrorDataNotAllowed: case kCFURLErrorUnknown: case kCFURLErrorHTTPTooManyRedirects:
		default:
			errCode = KGORequestErrorOther;
			break;
	}
    
    return errCode;
}

- (id)init {
    self = [super init];
    if (self) {
		self.cachePolicy = NSURLRequestUseProtocolCachePolicy;
		self.timeout = 30;
		self.expectedResponseType = [NSDictionary class];
	}
	return self;
}

- (BOOL)connectWithResponseType:(Class)responseType callback:(JSONObjectHandler)callback
{
    self.handler = [[callback copy] autorelease];
    self.expectedResponseType = responseType;
    return [self connect];
}

- (BOOL)connectWithCallback:(JSONObjectHandler)callback
{
    self.handler = [[callback copy] autorelease];
    return [self connect];
}

- (BOOL)connect {
    NSError *error = nil;
    NSDictionary *userInfo = nil;
    BOOL success = NO;
    
    if (self.minimumDuration && [self isUnderMinimumDuration]) {
        // don't want to show an error just because the data is fresh
		[self.delegate requestWillTerminate:self];
        [self cancel];
        return NO;
        
    } else if (_connection) {
        userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"could not connect because the connection is already in use", @"message", nil];
        error = [NSError errorWithDomain:KGORequestErrorDomain code:KGORequestErrorBadRequest userInfo:userInfo];

	} else {
        DLog(@"requesting %@", [self.url absoluteString]);
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url cachePolicy:self.cachePolicy timeoutInterval:self.timeout];
        static NSString *userAgent = nil;
        if (userAgent == nil) {
            NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
            userAgent = [[NSString alloc] initWithFormat:@"%@/%@ (%@ %@)",
                         [infoDict objectForKey:@"CFBundleName"],
                         [infoDict objectForKey:@"CFBundleVersion"],
                         (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? @"iPad" : @"iPhone",
                         [[UIDevice currentDevice] systemVersion]];
        }
        [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];

        if (self.ifModifiedSince) {
            NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
            [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
            [formatter setDateFormat:@"EEE', 'dd' 'MM' 'yyyy' 'HH':'mm':'ss' GMT'"];
            NSString *dateString = [formatter stringFromDate:self.ifModifiedSince];
            [request setValue:dateString forHTTPHeaderField:@"If-Modified-Since"];
        }

        if (![NSURLConnection canHandleRequest:request]) {
            userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"cannot handle request: %@", [self.url absoluteString]], @"message", nil];
            error = [NSError errorWithDomain:KGORequestErrorDomain code:KGORequestErrorBadRequest userInfo:userInfo];
        } else {
            _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
            if (_connection) {
                [self retain];
                [_data release];
                _data = [[NSMutableData alloc] init];
                success = YES;
            }
        }
    }
    
    if (!success) {
        if (!error) {
            userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"could not connect to url: %@", [self.url absoluteString]], @"message", nil];
            error = [NSError errorWithDomain:KGORequestErrorDomain code:KGORequestErrorBadRequest userInfo:userInfo];
        }
        [[KGORequestManager sharedManager] showAlertForError:error request:self];
    }
    
    if (success) {
        [KGO_SHARED_APP_DELEGATE() showNetworkActivityIndicator];
    }
    
	return success;
}

- (BOOL)isUnderMinimumDuration
{
    NSDictionary *preferences = [[NSUserDefaults standardUserDefaults] dictionaryForKey:KGORequestDurationPrefKey];
    if (preferences) {    
        NSString *requestID = [self.url absoluteString];
        NSDate *lastRequestTime = [preferences dateForKey:requestID];
DLog(@"connection lastrequested at %@ %.0f", lastRequestTime, [lastRequestTime timeIntervalSinceNow]);
        if (lastRequestTime && [lastRequestTime timeIntervalSinceNow] + self.minimumDuration >= 0) {
            // lastRequestTime is more recent than (now - duration)
            return YES;
        }
    }

    return NO;
}

- (void)cancel {
	// we still may be retained by other objects
	self.delegate = nil;
    self.result = nil;
	
	[_data release];
	_data = nil;
    
    if (_connection) {
        [_connection cancel];
        [_connection release];
        _connection = nil;
        [KGO_SHARED_APP_DELEGATE() hideNetworkActivityIndicator];
        [self release];
    }
}

- (void)dealloc {
	self.delegate = nil;
    self.result = nil;
	[_data release];
    if (_connection) {
        DLog(@"Warning: KGORequest is not retained but has a connection reference. This should never happen.");
        [_connection cancel];
        [_connection release];
        [KGO_SHARED_APP_DELEGATE() hideNetworkActivityIndicator];
    }
	self.url = nil;
	self.module = nil;
	self.path = nil;
	self.getParams = nil;
	self.format = nil;
	self.handler = nil;
	[super dealloc];
}

#pragma mark NSURLConnection

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _contentLength = [response expectedContentLength];
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        // TODO: decide how we want to handle this more generically
        // currently anyone who doesn't implement the callback will show the user a needless error
        if (statusCode == 304 && [self.delegate respondsToSelector:@selector(requestResponseUnchanged:)]) {
            [self.delegate requestResponseUnchanged:self];
        }
    }
    
	// could receive multiple responses (e.g. from redirect), so reset tempData with every request 
    // (last request received will deliver payload)
	// TODO: we may want to do something about redirects
	[_data setLength:0];
    if ([self.delegate respondsToSelector:@selector(requestDidReceiveResponse:)]) {
        [self.delegate requestDidReceiveResponse:self];
    }
}

// called repeatedly until connection is finished
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[_data appendData:data];
    if (_contentLength != NSURLResponseUnknownLength && [delegate respondsToSelector:@selector(request:didMakeProgress:)]) {
        NSUInteger lengthComplete = [_data length];
        CGFloat progress = (CGFloat)lengthComplete / (CGFloat)_contentLength;
        [delegate request:self didMakeProgress:progress];
    }
}

// no further messages will be received after this
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[_connection release];
	_connection = nil;

    [KGO_SHARED_APP_DELEGATE() hideNetworkActivityIndicator];
	
	if (!self.format || [self.format isEqualToString:@"json"]) {
        
		NSString *jsonString = [[[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding] autorelease];
		
		[_data release];
		_data = nil;
		
		if (!jsonString) {
			NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"empty response", @"message", nil];
			[self terminateWithErrorCode:KGORequestErrorBadResponse userInfo:params];
			return;
		}
		
		SBJsonParser *jsonParser = [[[SBJsonParser alloc] init] autorelease];
		NSError *error = nil;
		id parsedResult = [jsonParser objectWithString:jsonString error:&error];
		if (error) {
			[self terminateWithErrorCode:KGORequestErrorBadResponse userInfo:[error userInfo]];
			return;
		}
		
		if (![parsedResult isKindOfClass:[NSDictionary class]]) {
			NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"cannot parse response", @"message", nil];
			[self terminateWithErrorCode:KGORequestErrorBadResponse userInfo:params];
			return;
		}
        
		NSDictionary *resultDict = (NSDictionary *)parsedResult;
		id responseError = [resultDict objectForKey:@"error"];
		if (![responseError isKindOfClass:[NSNull class]]) {
            // TODO: handle this more thoroughly
			[self terminateWithErrorCode:KGORequestErrorServerMessage userInfo:responseError];
			return;
		}
		
        // TODO: do something with this
        NSInteger version = [resultDict integerForKey:@"version"];
        if (version) {
            ;
        }
        
		self.result = [resultDict objectForKey:@"response"];
		
	} else {
		self.result = [_data autorelease];
		_data = nil;
	}
	
	BOOL canProceed = [self.result isKindOfClass:self.expectedResponseType];
	if (!canProceed) { 
		NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"result type does not match expected response type", @"message", nil];
		[self terminateWithErrorCode:KGORequestErrorBadResponse userInfo:errorInfo];
		return;
	}
    
    // at this point we consider the request successful
    if (self.minimumDuration) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *preferences = [userDefaults dictionaryForKey:KGORequestDurationPrefKey];
        if (!preferences) {
            preferences = [NSDictionary dictionary];
        }
        NSMutableDictionary *mutablePrefs = [[preferences mutableCopy] autorelease];

        NSString *requestID = [self.url absoluteString];
        [mutablePrefs setObject:[NSDate date] forKey:requestID];
        
        [userDefaults setObject:mutablePrefs forKey:KGORequestDurationPrefKey];
        [userDefaults synchronize];
    }
    
	if (self.handler != nil) {
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(runHandlerOnResult:) object:self.result];
		[self performSelector:@selector(setHandler:) onThread:_thread withObject:self.handler waitUntilDone:NO];
		[_thread start];
	} else {
		if ([self.delegate respondsToSelector:@selector(request:didReceiveResult:)]) {
			[self.delegate request:self didReceiveResult:self.result];
		}
		
		[self.delegate requestWillTerminate:self];
		[self release];
	}
}

// no further messages will be received after this
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[_connection release];
	_connection = nil;
	[_data release];
	_data = nil;

    DLog(@"connection failed with error %d: %@", [error code], [error description]);
    
    [KGO_SHARED_APP_DELEGATE() hideNetworkActivityIndicator];
    KGORequestErrorCode errCode = [KGORequest internalCodeForNSError:error];
	
	[self terminateWithErrorCode:errCode userInfo:[error userInfo]];
}

#ifdef ALLOW_SELF_SIGNED_CERTIFICATE

// the implementations of the following two delegate methods allow NSURLConnection to proceed with self-signed certs
//http://stackoverflow.com/questions/933331/how-to-use-nsurlconnection-to-connect-with-ssl-for-an-untrusted-cert
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ([[[KGORequestManager sharedManager] host] isEqualToString:challenge.protectionSpace.host]) {
            [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]
                 forAuthenticationChallenge:challenge];
        }
    }
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

#endif

#pragma mark -

- (void)runHandlerOnResult:(id)result {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSInteger num = self.handler(result);
	[self performSelectorOnMainThread:@selector(handlerDidFinish:) withObject:[NSNumber numberWithInt:num] waitUntilDone:YES];
	[pool release];
}

- (void)handlerDidFinish:(NSNumber *)result {
	if ([self.delegate respondsToSelector:@selector(request:didHandleResult:)]) {
		[self.delegate request:self didHandleResult:[result integerValue]];
	}
	[self.delegate requestWillTerminate:self];
	[self release];
}

- (void)terminateWithErrorCode:(KGORequestErrorCode)errCode userInfo:(NSDictionary *)userInfo {
    if (self.url) {
        NSMutableDictionary *mutableUserInfo = [[userInfo mutableCopy] autorelease];
        [mutableUserInfo setObject:[self.url absoluteString] forKey:@"url"];
        userInfo = [NSDictionary dictionaryWithDictionary:mutableUserInfo];
    }
    
	NSError *kgoError = [NSError errorWithDomain:KGORequestErrorDomain code:errCode userInfo:userInfo];
	if ([self.delegate respondsToSelector:@selector(request:didFailWithError:)]) {
		[self.delegate request:self didFailWithError:kgoError];
	} else {
		[[KGORequestManager sharedManager] showAlertForError:kgoError request:self];
	}
	
	[self.delegate requestWillTerminate:self];
	[self release];
}

@end
