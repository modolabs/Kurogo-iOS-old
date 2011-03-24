#import "ModalLoginWebViewController.h"
#import "KGORequestManager.h"
#import "KGOAppDelegate.h"

// these constants are defined in Kurogo-Mobile-Web
// TODO: put this config in more transparent place
static NSString * const UserHashCookieName = @"lh";
static NSString * const UserTokenCookieName = @"lt";

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
    //NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[[KGORequestManager sharedManager] hostURL]];
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];

    BOOL userHashCookieExists = NO;
    BOOL userTokenCookieExists = NO;
    
    for (NSHTTPCookie *aCookie in cookies) {
        DLog(@"cookie: %@", [aCookie description]);
        NSString *name = [aCookie name];
        if ([name isEqualToString:UserHashCookieName]) {
            userHashCookieExists = YES;
        } else if ([name isEqualToString:UserTokenCookieName]) {
            userTokenCookieExists = YES;
        }
        if (userTokenCookieExists && userHashCookieExists) {
            
            [self.loginModule userDidLogin];
            
            return NO;
        }
    }
    
    return [super webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
}

@end
