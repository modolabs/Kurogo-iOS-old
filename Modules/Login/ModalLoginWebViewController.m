#import "ModalLoginWebViewController.h"
#import "KGORequestManager.h"
#import "KGOAppDelegate.h"
#import "LoginModule.h"

@implementation ModalLoginWebViewController

@synthesize loginModule;

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

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([[KGORequestManager sharedManager] isUserLoggedIn]) {
        [self.loginModule userDidLogin];
        return NO;
    }
    
    return [super webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
}

@end
