#import <UIKit/UIKit.h>
#import "KGORequestManager.h"
#import <MessageUI/MFMailComposeViewController.h>

@interface AboutTableViewController : UITableViewController <
KGORequestDelegate, MFMailComposeViewControllerDelegate> {
    
    BOOL showBuildNumber;
    
    NSDictionary * resultDict;
    NSMutableArray * resultKeys;
    
    UIView * loadingView;
    UIActivityIndicatorView * loadingIndicator;
}

@property (nonatomic, retain) KGORequest * request;
@property (nonatomic, retain) NSString * moduleTag;
@property (nonatomic, retain) NSDictionary * resultDict;
@property (nonatomic, retain) NSMutableArray * resultKeys;

@property (nonatomic, retain) UIView * loadingView;
@property (nonatomic, retain) UIActivityIndicatorView * loadingIndicator;

- (void) addLoadingView;
- (void) removeLoadingView; 

@end
