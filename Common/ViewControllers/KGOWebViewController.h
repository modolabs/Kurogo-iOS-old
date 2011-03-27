#import <UIKit/UIKit.h>


@interface KGOWebViewController : UIViewController <UIWebViewDelegate> {
    
    UIWebView *_webView;
    UIActivityIndicatorView *_loadingView;
    NSURL *_requestURL;

    NSMutableURLRequest *_request;
    NSURLConnection *_connection;
    NSMutableData *_data;
    
    NSURLResponse *_latestResponse;
    
    NSString * htmlString;

}

@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSData *data;

@property (nonatomic, retain) NSURL *requestURL;

@property (nonatomic, retain) NSString * htmlString;

- (void)setRequestURL:(NSURL *)requestURL;
- (void) setLoadHtmlString: (NSString *) htmlStringText;

@end
