#import "KGOWebViewController.h"
#import "KGORequestManager.h"
#import "KGOAppDelegate.h"
#import "KGOHTMLTemplate.h"

@implementation KGOWebViewController

@synthesize loadsLinksExternally, webView = _webView;
@synthesize HTMLString;

- (void)dealloc
{
    self.webView.delegate = nil;
    self.webView = nil;
    
    self.requestURL = nil;
    [_templateStack release];
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
    
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
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

- (void)applyTemplate:(NSString *)filename
{
    if (!_templateStack) {
        _templateStack = [[NSMutableArray alloc] init];
    }

    if ([_templateStack containsObject:filename]) {
        return;
    } else {
        [_templateStack addObject:filename];
    }
    
    KGOHTMLTemplate *template = [KGOHTMLTemplate templateWithPathName:filename];
    NSString *wrappedString = [template stringWithReplacements:[NSDictionary dictionaryWithObjectsAndKeys:HTMLString, @"BODY", nil]];
    NSURL *url = [NSURL URLWithString:[[NSBundle mainBundle] resourcePath]];
    if (_webView) {
        [_webView loadHTMLString:wrappedString baseURL:url];
    } else {
        HTMLString = [wrappedString retain];
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    }
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma marke - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *scheme = [request.URL scheme];
    
    if ([scheme isEqualToString:[KGO_SHARED_APP_DELEGATE() defaultURLScheme]]) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    
    if (self.loadsLinksExternally && ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"])) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
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

@end
