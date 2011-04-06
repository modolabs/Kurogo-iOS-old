#import <UIKit/UIKit.h>

@interface KGOWebViewController : UIViewController <UIWebViewDelegate> {
    
    UIWebView *_webView;
    UIActivityIndicatorView *_loadingView;
    NSURL *_requestURL;
    
    NSString * HTMLString;

    NSMutableArray *_templateStack;
}

@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSURL *requestURL;

@property (nonatomic, retain) NSString * HTMLString;

@property (nonatomic) BOOL loadsLinksExternally;

- (void) showHTMLString: (NSString *) HTMLStringText;

- (void)applyTemplate:(NSString *)filename;

@end
