#import "ConnectionWrapper.h"

#define TIMEOUT_INTERVAL	30.0


@implementation ConnectionWrapper

@synthesize delegate, isConnected, urlConnection, theURL;

// designated initializer
- (id)initWithDelegate:(id<ConnectionWrapperDelegate>)theDelegate {
    self = [self init];
    self.delegate = theDelegate;
    return self;
}

- (id)init {
	self = [super init];

	if (self != nil) {
		isConnected = false;
		tempData = nil;
		self.urlConnection = nil;
		[self resetObjects];
	}
	
	return self;
}

- (void)dealloc {
    self.delegate = nil;
    [urlConnection release];
	[tempData release];
    [theURL release];
	[super dealloc];
}

- (void)resetObjects {
	isConnected = false;
	[tempData release];
    tempData = nil;
}

- (void)cancel {
    if (isConnected) {
        [urlConnection cancel];
        self.urlConnection = nil;
        [self resetObjects];
    }
}

#pragma mark -
#pragma mark NSURLConnection delegation
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    contentLength = [response expectedContentLength];
	[tempData setLength:0];	// could receive multiple responses (e.g. from redirect), so reset tempData with every request (last request received will deliver payload)
    if ([delegate respondsToSelector:@selector(connectionDidReceiveResponse:)]) {
        [delegate connectionDidReceiveResponse:self];	// have the delegate decide what to do with the error
    }
}

// internal method used by NSURLConnection
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {	// should be repeatedly called until download is complete. this method will only be called after there are no more responses received (see above method)
	[tempData appendData:data];		// got some data in, so append it
    if (contentLength != NSURLResponseUnknownLength && [delegate respondsToSelector:@selector(connection:madeProgress:)]) {
        NSUInteger lengthComplete = [tempData length];
        CGFloat progress = (CGFloat)lengthComplete / (CGFloat)contentLength;
        [delegate connection:self madeProgress:progress];
    }
}

// internal method used by NSURLConnection
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {	// download's done, so do something with the data
    if (connection == self.urlConnection) {
        isConnected = false;
        [delegate connection:self handleData:tempData];
        self.urlConnection = nil; // release the NSURLConnection object
    }
}

// internal method used by NSURLConnection
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {	// download failed for some reason, so handle it
    if (connection == self.urlConnection) {
        isConnected = false;
        self.urlConnection = nil; // release the connection object

        id alertDelegate = nil;
        if ([self.delegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)]) {
            alertDelegate = self.delegate;
        }
        
        if ([self.delegate connection:self shouldDisplayAlertForError:error]) {
            NSString *title = nil;
            NSString *message = nil;
            switch ([error code]) {
                case kCFURLErrorCannotConnectToHost:
                case kCFURLErrorCannotFindHost:
                    title = NSLocalizedString(@"Connection Failed", nil);
                    message = NSLocalizedString(@"Could not connect to server. Please try again later.", nil);
                    break;
                case kCFURLErrorNotConnectedToInternet:
                    title = NSLocalizedString(@"Connection Failed", nil);
                    message = NSLocalizedString(@"Please check your Internet connection and try again later.", nil);
                    break;
                case kCFURLErrorTimedOut:
                    title = NSLocalizedString(@"Connection Failed", nil);
                    message = NSLocalizedString(@"Server is taking too long to respond. Please try again later.", nil);
                    break;
                case kCFURLErrorBadServerResponse: case kCFURLErrorZeroByteResource:
                case kCFURLErrorCannotDecodeRawData: case kCFURLErrorCannotDecodeContentData:
                case kCFURLErrorCannotParseResponse:
                    title = NSLocalizedString(@"Error Connecting", nil);
                    message = NSLocalizedString(@"Bad response from server. Please try again later.", nil);
                    break;
                case kCFURLErrorUnknown: // all other CFURLConnection and CFURLProtocol errors
                case kCFURLErrorCancelled: case kCFURLErrorBadURL: case kCFURLErrorUnsupportedURL:
                case kCFURLErrorNetworkConnectionLost: case kCFURLErrorDNSLookupFailed:
                case kCFURLErrorHTTPTooManyRedirects: case kCFURLErrorResourceUnavailable:
                case kCFURLErrorRedirectToNonExistentLocation: case kCFURLErrorUserCancelledAuthentication:
                case kCFURLErrorUserAuthenticationRequired: case kCFURLErrorInternationalRoamingOff:
                case kCFURLErrorCallIsActive: case kCFURLErrorDataNotAllowed:
                case kCFURLErrorRequestBodyStreamExhausted: case kCFURLErrorFileDoesNotExist:
                case kCFURLErrorFileIsDirectory: case kCFURLErrorNoPermissionsToReadFile:
                case kCFURLErrorDataLengthExceedsMaximum:
                    title = NSLocalizedString(@"Error Connecting", nil);
                    message = NSLocalizedString(@"Problem connecting to server. Please try again later.", nil);
                    break;
                default:
                    break;
            }
            if (title != nil) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Failed", nil)
                                                                message:message
                                                               delegate:alertDelegate
                                                      cancelButtonTitle:NSLocalizedString(@"OK", nil) 
                                                      otherButtonTitles:nil];
                [alert show];
                [alert release];
            }
        }

        if ([delegate respondsToSelector:@selector(connection:handleConnectionFailureWithError:)]) {
            [delegate connection:self handleConnectionFailureWithError:error];	// have the delegate decide what to do with the error
        }
        
    }
}

#pragma mark Request methods

-(BOOL)requestDataFromURL:(NSURL *)url {
    return [self requestDataFromURL:url allowCachedResponse:NO];
}

-(BOOL)requestDataFromURL:(NSURL *)url allowCachedResponse:(BOOL)shouldCache {
	if (isConnected) {	// if there's already a connection established
		return NO;		// notify of failure
	}
	
    DLog(@"Requesting URL %@ %@", url, ((shouldCache) ? @"allowing cached responses" : @"ignoring cache"));
    
	// prep the variables for incoming data
	[self resetObjects];
	
    self.theURL = url;
    
	// create the request
    NSURLRequestCachePolicy cachePolicy = (shouldCache) ? NSURLRequestReturnCacheDataElseLoad : NSURLRequestReloadIgnoringLocalAndRemoteCacheData;

	NSURLRequest *request = [NSURLRequest requestWithURL:	url
											 cachePolicy:	cachePolicy	// Make sure not to cache in case of update for URL
										 timeoutInterval:	TIMEOUT_INTERVAL];
	
	// 'pre-flight' check to make sure it will go through
	if(![NSURLConnection canHandleRequest:request]) {	// if the request will fail
		[self resetObjects];							// then release & reset variables
		return NO;										// and notify of failure
	}
	
	self.urlConnection = [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];	// try and form a connection
	
	if (self.urlConnection) {			// if the connection was successfully formed
		isConnected = YES;								// record that it's successful
		tempData = [ [NSMutableData data] retain ];		// then allocate memory for incoming data
		return YES;									// and notify of success
	}
	
	// otherwise, connection was not successfully formed
	[self resetObjects];		// so reset & release temp objects
	return NO;				// and notify of failure
}

@end
