#import "ModalLoginWebViewController.h"
#import "KGORequestManager.h"
#import "KGOAppDelegate.h"
#import "LoginModule.h"

@implementation ModalLoginWebViewController

@synthesize data = _data, connection = _connection, loginModule;

- (void)dealloc
{
    if (self.connection) {
        [self.connection cancel];
        self.connection = nil;
    }
    self.loginModule = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissModalViewControllerAnimated:)
                                                 name:KGODidLoginNotification
                                               object:nil];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"attempting to load %@", request.URL);

    if ([[KGORequestManager sharedManager] isUserLoggedIn]) {
        [KGO_SHARED_APP_DELEGATE() dismissAppModalViewControllerAnimated:YES];
        return NO;
    }
    
    // we have to keep calling this because we can't tell when the user is 
    // looking at which screen
    if ([[KGORequestManager sharedManager] requestingSessionInfo]) {
        [webView performSelector:@selector(loadRequest:) withObject:request afterDelay:0.1];
        return NO;
    }
    
    [[KGORequestManager sharedManager] requestSessionInfo];
    
#ifdef USE_MOBILE_DEV
    
    NSString *scheme = [request.URL scheme];
    
    // the webview will refuse to load if the server uses a self-signed cert
    // so we will get the contents directly and load it into the webview
    if ([scheme isEqualToString:@"https"]
        && ([[[request URL] host] rangeOfString:[[KGORequestManager sharedManager] host]].location != NSNotFound
            || [[[request URL] host] rangeOfString:@"google.com"].location != NSNotFound) // blacklisting as part of login process
    ) {
        if (request != _request) {
            [_request release];
            _request = [request mutableCopy];
            NSLog(@"%@", [_request HTTPMethod]);
            NSLog(@"post data: %@", [[[NSString alloc] initWithData:[_request HTTPBody] encoding:NSUTF8StringEncoding] autorelease]);
            
            self.data = [NSMutableData data];
            
            self.connection = [[[NSURLConnection alloc] initWithRequest:_request delegate:self] autorelease];
            [self.connection start];
        }
        return NO;
        
    } else if ([scheme isEqualToString:@"applewebdata"]) {
        // crazy experiment to make google apps work
        
        if (request != _request) {
            [_request release];
            _request = [request mutableCopy];
            
            NSLog(@"last response was %@", [_latestResponse URL]);
            
            NSLog(@"%@", [_request HTTPMethod]);
            NSLog(@"post data: %@", [[[NSString alloc] initWithData:[_request HTTPBody] encoding:NSUTF8StringEncoding] autorelease]);
            
            NSMutableArray *oldComponents = [[[[_latestResponse URL] pathComponents] mutableCopy] autorelease];
            NSArray *newComponents = [[_request URL] pathComponents];
            [oldComponents removeLastObject];
            [oldComponents addObject:[newComponents lastObject]];
            NSCharacterSet *charset = [NSCharacterSet characterSetWithCharactersInString:@"/"];
            NSString *path = [[oldComponents componentsJoinedByString:@"/"] stringByTrimmingCharactersInSet:charset];
            
            _request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@/%@?%@",
                                                 [[_latestResponse URL] scheme],
                                                 [[_latestResponse URL] host],
                                                 path,
                                                 [[_latestResponse URL] query]]];
            
            NSLog(@"modified url to %@", _request.URL);
            
            self.data = [NSMutableData data];
            
            self.connection = [[[NSURLConnection alloc] initWithRequest:_request delegate:self] autorelease];
            [self.connection start];
        }
        return NO;
    }
#endif
    return YES;
}

#ifdef USE_MOBILE_DEV
#pragma mark - NSURLConnection
/*
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    NSLog(@"response: %@, storage: %d, userInfo: %@",
          [cachedResponse description], cachedResponse.storagePolicy, cachedResponse.userInfo);
    
    return cachedResponse;
}
*/
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
	[_data setLength:0];
    
    [_latestResponse release];
    _latestResponse = [response retain];
    
    // not sure why cookies aren't set for some login authorities
    NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)_latestResponse;
    NSDictionary *headers = [HTTPResponse allHeaderFields];
    DLog(@"%@", [_latestResponse URL]);
    DLog(@"%@", headers);
    if ([headers objectForKey:@"Set-Cookie"]) {
        NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:headers forURL:[response URL]];
        for (NSHTTPCookie *aCookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:aCookie];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[_data appendData:data];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    [_latestResponse release];
    _latestResponse = [redirectResponse retain];
    
    NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)_latestResponse;
    NSDictionary *headers = [HTTPResponse allHeaderFields];
    DLog(@"%@", [_latestResponse URL]);
    DLog(@"%@", headers);
    if ([headers objectForKey:@"Set-Cookie"]) {
        NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:headers forURL:[HTTPResponse URL]];
        for (NSHTTPCookie *aCookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:aCookie];
        }
    }
    return request;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.connection = nil;
    NSString *htmlString = [[[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding] autorelease];
    if (htmlString) {
        // at this point we are doing a lot of incredibly sad and fragile string
        // string replacements -- relying on the way kurogo creates these
        // references -- because setting the baseURL results in an infnite loop
        // TODO: find a long term solution to the self-signed certificate
        // problem, possibly incorporating ASIHTTPRequest.
        NSURL *url = [_latestResponse URL];
        if ([[url host] rangeOfString:[[KGORequestManager sharedManager] host]].location != NSNotFound) {
            NSString *hrefURL = [[[KGORequestManager sharedManager] hostURL] absoluteString];
            NSString *srcURL = [[[KGORequestManager sharedManager] serverURL] absoluteString];
            NSString *originalURL = [NSString stringWithFormat:@"%@/%@", hrefURL, [self.requestURL path]];
            
            htmlString = [htmlString stringByReplacingOccurrencesOfString:@"src=\""
                                                               withString:[NSString stringWithFormat:@"src=\"%@/", srcURL]];
            
            htmlString = [htmlString stringByReplacingOccurrencesOfString:@"href=\"/"
                                                               withString:[NSString stringWithFormat:@"href=\"%@/", hrefURL]];
            
            htmlString = [htmlString stringByReplacingOccurrencesOfString:@"action=\""
                                                               withString:[NSString stringWithFormat:@"action=\"%@/", originalURL]];
        }
        
        [self.webView loadHTMLString:htmlString baseURL:nil];
    }
    self.data = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"%@", [error description]);
    
    self.connection = nil;
    self.data = nil;
}

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

@end
