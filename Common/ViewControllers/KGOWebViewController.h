#import <UIKit/UIKit.h>

@class KGOWebViewController;

@protocol KGOWebViewControllerDelegate <NSObject>

@optional

- (void)webViewControllerFrameLoadInterrupted:(KGOWebViewController *)webVC;
- (BOOL)webViewController:(KGOWebViewController *)webVC shouldLoadExternallyForURL:(NSURL *)url;

@end


@interface KGOWebViewController : UIViewController <UIWebViewDelegate> {
    
    UIWebView *_webView;
    UIActivityIndicatorView *_loadingView;
    NSURL *_requestURL;
    
    NSString * HTMLString;

    NSMutableArray *_templateStack;
}

@property (nonatomic, assign) id<KGOWebViewControllerDelegate> delegate;
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSURL *requestURL;

@property (nonatomic, retain) NSString * HTMLString;

@property (nonatomic) BOOL loadsLinksExternally;

- (void) showHTMLString: (NSString *) HTMLStringText;

- (void)applyTemplate:(NSString *)filename;

@end
