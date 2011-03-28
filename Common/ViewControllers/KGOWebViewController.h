#import <UIKit/UIKit.h>


@interface KGOWebViewController : UIViewController <UIWebViewDelegate> {
    
    UIWebView *_webView;
    UIActivityIndicatorView *_loadingView;
    NSURL *_requestURL;

    NSMutableURLRequest *_request;
    NSURLConnection *_connection;
    NSMutableData *_data;
    
    NSURLResponse *_latestResponse;
    
    NSString * HTMLString;

}

@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSData *data;

@property (nonatomic, retain) NSURL *requestURL;

@property (nonatomic, retain) NSString * HTMLString;

- (void) showHTMLString: (NSString *) HTMLStringText;

@end
