#import "KGOWebViewController.h"
#import "KGORequestManager.h"

@implementation KGOWebViewController

@synthesize data = _data, connection = _connection;

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

#ifdef USE_MOBILE_DEV
    // the webview will refuse to load if the server uses a self-signed cert
    // so we will get the contents directly and load it into the webview
    if ([[[request URL] scheme] isEqualToString:@"https"]) {
        if (request != _request) {
            [_request release];
            _request = [request retain];
            
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

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[_data setLength:0];
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
        NSString *hrefURL = [[[KGORequestManager sharedManager] hostURL] absoluteString];
        NSString *srcURL = [[[KGORequestManager sharedManager] serverURL] absoluteString];
        NSString *originalURL = [NSString stringWithFormat:@"%@/%@", hrefURL, [self.requestURL path]];
        
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"href=\"/"
                                                           withString:[NSString stringWithFormat:@"href=\"%@/", hrefURL]];
        
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"src=\""
                                                           withString:[NSString stringWithFormat:@"src=\"%@/", srcURL]];
        
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"action=\""
                                                           withString:[NSString stringWithFormat:@"action=\"%@/", originalURL]];
        
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
