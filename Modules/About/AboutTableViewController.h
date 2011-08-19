#import <UIKit/UIKit.h>
#import "KGORequestManager.h"
#import <MessageUI/MFMailComposeViewController.h>

@interface AboutTableViewController : UITableViewController <
KGORequestDelegate, MFMailComposeViewControllerDelegate> {
    
    BOOL showBuildNumber;
    
    NSArray * resultArray;
    
    UIView * loadingView;
    UIActivityIndicatorView * loadingIndicator;
}

@property (nonatomic, retain) KGORequest * request;
@property (nonatomic, retain) NSString * moduleTag;
@property (nonatomic, retain) NSArray * resultArray;

@property (nonatomic, retain) UIView * loadingView;
@property (nonatomic, retain) UIActivityIndicatorView * loadingIndicator;

- (void) addLoadingView;
- (void) removeLoadingView; 

@end
