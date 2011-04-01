#import "KGOWebViewController.h"
#import "KGORequestManager.h"

@implementation KGOWebViewController

@synthesize data = _data, connection = _connection;
@synthesize HTMLString;

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    _webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _webView.delegate = self;

    [self.view addSubview:_webView];
    
    if (self.requestURL) {
        [_webView loadRequest:[NSURLRequest requestWithURL:self.requestURL]];
    }
    
    if (self.HTMLString != nil) {
        [_webView loadHTMLString:self.HTMLString baseURL:nil];
    }
    
    
}

- (NSURL *)requestURL
{
    return _requestURL;
}

- (void)setRequestURL:(NSURL *)requestURL
{
    [_requestURL release];
    _requestURL = [requestURL retain];
    
    if (_webView) {
        [_webView loadRequest:[NSURLRequest requestWithURL:self.requestURL]];
    }
}

- (void) showHTMLString: (NSString *) HTMLStringText
{
    [HTMLString release];
    self.HTMLString = HTMLStringText;
    
    if (_webView){
        [_webView loadHTMLString:self.HTMLString baseURL:nil];
    }
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma marke - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    DLog(@"loading request with url %@", request.URL);
    if ([[request.URL host] rangeOfString:@"foursquare.com"].location != NSNotFound)
        return YES;
    if ([[[request URL] scheme] isEqualToString:@"harvardreunion"]) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
        

#ifdef USE_MOBILE_DEV
    // the webview will refuse to load if the server uses a self-signed cert
    // so we will get the contents directly and load it into the webview
    if ([[[request URL] scheme] isEqualToString:@"https"]
       // && [[[request URL] host] isEqualToString:[[KGORequestManager sharedManager] host]]
    ) {
        if (request != _request) {
            [_request release];
            _request = [request mutableCopy];
            
            self.data = [NSMutableData data];
            
            self.connection = [[[NSURLConnection alloc] initWithRequest:_request delegate:self] autorelease];
            [self.connection start];
        }
        return NO;

    } else if ([[[request URL] scheme] isEqualToString:@"applewebdata"]) {
        // crazy experiment to make google apps work
        
        if (request != _request) {
            [_request release];
            _request = [request mutableCopy];
            
            NSMutableArray *oldComponents = [[[[_latestResponse URL] pathComponents] mutableCopy] autorelease];
            NSArray *newComponents = [[_request URL] pathComponents];
            [oldComponents removeLastObject];
            [oldComponents addObject:[newComponents lastObject]];
            NSCharacterSet *charset = [NSCharacterSet characterSetWithCharactersInString:@"/"];
            NSString *path = [[oldComponents componentsJoinedByString:@"/"] stringByTrimmingCharactersInSet:charset];
            
            _request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@/%@",
                                                 [[_latestResponse URL] scheme],
                                                 [[_latestResponse URL] host],
                                                 path]];

            self.data = [NSMutableData data];
            
            self.connection = [[[NSURLConnection alloc] initWithRequest:_request delegate:self] autorelease];
            [self.connection start];
        }
        return NO;
    }
#endif
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if (!_loadingView) {
        _loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [_loadingView startAnimating];
        _loadingView.center = self.view.center;
        [self.view addSubview:_loadingView];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [_loadingView removeFromSuperview];
    [_loadingView release];
    _loadingView = nil;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"%@", [error description]);
}

#ifdef USE_MOBILE_DEV
#pragma mark - NSURLConnection

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    NSLog(@"response: %@, storage: %d, userInfo: %@",
          [cachedResponse description], cachedResponse.storagePolicy, cachedResponse.userInfo);
    return cachedResponse;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[_data setLength:0];
    
    [_latestResponse release];
    _latestResponse = [response retain];
    
    // not sure why cookies aren't set for some login authorities
    NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)_latestResponse;
    NSDictionary *headers = [HTTPResponse allHeaderFields];
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
        
        //DLog(@"%@", htmlString);
        [_webView loadHTMLString:htmlString baseURL:nil];
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
