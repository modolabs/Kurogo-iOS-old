#import "KGOWebViewController.h"

@class LoginModule;

@interface ModalLoginWebViewController : KGOWebViewController {
    
    NSURLConnection *_connection;
    NSMutableURLRequest *_request;
    NSURLResponse *_latestResponse;
    NSMutableData *_data;
}

@property (nonatomic, assign) LoginModule *loginModule;
@property (nonatomic, retain) NSURLConnection *connection;

@property (nonatomic, retain) NSData *data;

@end
