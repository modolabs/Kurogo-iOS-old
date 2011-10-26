#import <UIKit/UIKit.h>

@class KGOWebViewController;

@protocol KGOWebViewControllerDelegate <NSObject>

@optional

- (void)webViewControllerFrameLoadInterrupted:(KGOWebViewController *)webVC;
- (BOOL)webViewController:(KGOWebViewController *)webVC shouldOpenSystemBrowserForURL:(NSURL *)url;

@end


@interface KGOWebViewController : UIViewController <UIWebViewDelegate, UIAlertViewDelegate> {
    
    UIWebView *_webView;
    UIActivityIndicatorView *_loadingView;
    NSURL *_requestURL;
    
    NSString *_HTMLString;

    NSMutableArray *_templateStack;
    
    UIView *_dismissView;
}

@property (nonatomic, assign) id<KGOWebViewControllerDelegate> delegate;
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSURL *requestURL;

@property (nonatomic, retain) NSString *HTMLString;

@property (nonatomic) BOOL loadsLinksInternally; // defaults to NO

// things that are applied later are "outside"
- (void)applyTemplate:(NSString *)filename;

// useful if a network connection causes a request to fail
- (void)retryRequest;

// UI for leaving when we get stuck in a full screen modal view
- (void)fadeInDismissControls;
- (void)showDismissControlsAnimated:(BOOL)animated;

@end
