#import "KGORequestManager.h"
#import "Foundation+KGOAdditions.h"
#import "JSON.h"
#import "KGOAppDelegate.h"

NSString * const KGORequestErrorDomain = @"com.modolabs.KGORequest.ErrorDomain";

@interface KGORequest (Private)

- (void)terminateWithErrorCode:(KGORequestErrorCode)errCode userInfo:(NSDictionary *)userInfo;

- (void)runHandlerOnResult:(id)result;

@end


@implementation KGORequest

@synthesize url, module, path, getParams, postParams, format, delegate, cachePolicy, timeout;
@synthesize expectedResponseType, handler;

- (id)init {
    self = [super init];
    if (self) {
		self.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
		self.timeout = 30;
		self.expectedResponseType = [NSDictionary class];
	}
	return self;
}

- (BOOL)connect {
    NSError *error = nil;
    NSDictionary *userInfo = nil;
    BOOL success = NO;
    
	if (_connection) {
        userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"could not connect because the connection is already in use", @"message", nil];
        error = [NSError errorWithDomain:KGORequestErrorDomain code:KGORequestErrorBadRequest userInfo:userInfo];
	} else {
        DLog(@"requesting %@", [self.url absoluteString]);
        
        NSURLRequest *request = [NSURLRequest requestWithURL:self.url cachePolicy:self.cachePolicy timeoutInterval:self.timeout];
        if (![NSURLConnection canHandleRequest:request]) {
            userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"cannot handle request: %@", [self.url absoluteString]], @"message", nil];
            error = [NSError errorWithDomain:KGORequestErrorDomain code:KGORequestErrorBadRequest userInfo:userInfo];
        } else {
            _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
            if (_connection) {
                [_data release];
                _data = [[NSMutableData alloc] init];
                [self retain];
                success = YES;
            }
        }
    }

    if (!success) {
        if (!error) {
            userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"could not connect to url: %@", [self.url absoluteString]], @"message", nil];
            error = [NSError errorWithDomain:KGORequestErrorDomain code:KGORequestErrorBadRequest userInfo:userInfo];
        }
        [[KGORequestManager sharedManager] showAlertForError:error];
    }
	return success;
}

- (void)cancel {
	// we still may be retained by other objects
	[_connection cancel];
	[_connection release];
	_connection = nil;
	
	self.delegate = nil;
	
	[_data release];
	_data = nil;

	[self release];
}

- (void)dealloc {
	self.delegate = nil;
	[_data release];
	[_connection cancel];
	[_connection release];
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
	// could receive multiple responses (e.g. from redirect), so reset tempData with every request (last request received will deliver payload)
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
	
	id result = nil;

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
        
		result = [resultDict objectForKey:@"response"];
		
	} else {
		result = [_data autorelease];
		_data = nil;
	}
	
	BOOL canProceed = [result isKindOfClass:self.expectedResponseType];
	if (!canProceed) {
		NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"result type does not match expected response type", @"message", nil];
		[self terminateWithErrorCode:KGORequestErrorBadResponse userInfo:errorInfo];
		return;
	}

	if (self.handler != nil) {
		_thread = [[NSThread alloc] initWithTarget:self selector:@selector(runHandlerOnResult:) object:result];
		[self performSelector:@selector(setHandler:) onThread:_thread withObject:self.handler waitUntilDone:NO];
		[_thread start];
		//NSInteger num = self.handler(result);
		//if ([self.delegate respondsToSelector:@selector(request:didHandleResult:)]) {
		//	[self.delegate request:self didHandleResult:num];
		//}
	} else {
		if ([self.delegate respondsToSelector:@selector(request:didReceiveResult:)]) {
			[self.delegate request:self didReceiveResult:result];
		}
		
		[self.delegate requestWillTerminate:self];
		[self release];
	}
}

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

// no further messages will be received after this
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[_connection release];
	_connection = nil;
	[_data release];
	_data = nil;
	
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
	
	[self terminateWithErrorCode:errCode userInfo:[error userInfo]];
}

- (void)terminateWithErrorCode:(KGORequestErrorCode)errCode userInfo:(NSDictionary *)userInfo {
	NSError *kgoError = [NSError errorWithDomain:KGORequestErrorDomain code:errCode userInfo:userInfo];
	if ([self.delegate respondsToSelector:@selector(request:didFailWithError:)]) {
		[self.delegate request:self didFailWithError:kgoError];
	} else {
		[[KGORequestManager sharedManager] showAlertForError:kgoError];
	}
	
	[self.delegate requestWillTerminate:self];
	[self release];
}
					 
@end



@implementation KGORequestManager

@synthesize host = _host;

+ (KGORequestManager *)sharedManager {
	static KGORequestManager *s_sharedManager = nil;
	if (s_sharedManager == nil) {
		s_sharedManager = [[KGORequestManager alloc] init];
	}
	return s_sharedManager;
}

- (KGORequest *)requestWithDelegate:(id<KGORequestDelegate>)delegate module:(NSString *)module path:(NSString *)path params:(NSDictionary *)params {
	BOOL authorized = YES; // TODO: determine this value
	KGORequest *request = nil;
	if (authorized) {
		request = [[[KGORequest alloc] init] autorelease];
		request.delegate = delegate;
		NSURL *requestBaseURL = [[_baseURL URLByAppendingPathComponent:module] URLByAppendingPathComponent:path];
		NSMutableDictionary *mutableParams = [[params mutableCopy] autorelease];
		if (_accessToken) {
			[mutableParams setObject:_accessToken forKey:@"token"];
		}

		request.url = [NSURL URLWithQueryParameters:params baseURL:requestBaseURL];
		request.module = module;
		request.path = path;
		request.getParams = mutableParams;
	} else {
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:nil];
		NSError *error = [NSError errorWithDomain:KGORequestErrorDomain code:KGORequestErrorForbidden userInfo:userInfo];
		[self showAlertForError:error];
	}
	return request;
}

- (void)showAlertForError:(NSError *)error {
    DLog(@"%@", [error userInfo]);
    
	NSString *title = nil;
	NSString *message = nil;
	
	switch ([error code]) {
		case KGORequestErrorBadRequest: case KGORequestErrorUnreachable:
			title = NSLocalizedString(@"Connection Failed", nil);
			message = NSLocalizedString(@"Could not connect to server. Please try again later.", nil);
			break;
		case KGORequestErrorDeviceOffline:
			title = NSLocalizedString(@"Connection Failed", nil);
			message = NSLocalizedString(@"Please check your Internet connection and try again.", nil);
			break;
		case KGORequestErrorTimeout:
			title = NSLocalizedString(@"Connection Timed Out", nil);
			message = NSLocalizedString(@"Server is taking too long to respond. Please try again later.", nil);
			break;
		case KGORequestErrorForbidden:
			title = NSLocalizedString(@"Unauthorized Request", nil);
			message = NSLocalizedString(@"Unable to perform this request. Please check your login credentials.", nil);
			break;
		case KGORequestErrorVersionMismatch:
			title = NSLocalizedString(@"Unsupported Request", nil);
			NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
			message = [NSString stringWithFormat:@"%@ %@",
					   NSLocalizedString(@"Request is not supported in this version of", nil),
					   [infoDict objectForKey:@"CFBundleName"]];
			break;
		case KGORequestErrorBadResponse: case KGORequestErrorOther:
			title = NSLocalizedString(@"Connection Failed", nil);
			message = NSLocalizedString(@"Problem connecting to server. Please try again later.", nil);
			break;
		case KGORequestErrorServerMessage:
			title = [[error userInfo] objectForKey:@"title"];
			message = [[error userInfo] objectForKey:@"message"];
			break;
		case KGORequestErrorInterrupted: // don't show alert
		default:
			break;
	}
	
	if (title) {
		UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] autorelease];
		[alertView show];
	}
}

#pragma mark initialization

- (id)init {
    self = [super init];
    if (self) {
        NSDictionary *configDict = [(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] appConfig];
        NSDictionary *servers = [configDict objectForKey:@"Servers"];
        NSDictionary *security = [configDict objectForKey:@"Security"];
        BOOL useHTTPS = [security boolForKey:@"UseHTTPS"];
        
        _uriScheme = useHTTPS ? @"https" : @"http";
        // TODO: allow this mode to be changed
        _host = [[servers objectForKey:@"development"] retain];
        NSString *apiPath = [NSString stringWithFormat:@"/%@", [servers objectForKey:@"APIPath"]];
		_baseURL = [[NSURL alloc] initWithScheme:_uriScheme host:_host path:apiPath];
	}
	return self;
}

- (void)registerWithKGOServer {
	
}

- (void)authenticateWithKGOServer {
	
}

- (void)dealloc {
	self.host = nil;
	[_uriScheme release];
	[_accessToken release];
	[_apiVersionsByModule release];
	[super dealloc];
}

#pragma mark KGORequestDelegate


- (void)requestWillTerminate:(KGORequest *)request {
}

- (void)request:(KGORequest *)request didFailWithError:(NSError *)error {
}

- (void)request:(KGORequest *)request receivedResultDict:(NSDictionary *)result {
}

@end
