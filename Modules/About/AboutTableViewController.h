#import <UIKit/UIKit.h>
#import "KGORequestManager.h"
#import <MessageUI/MFMailComposeViewController.h>

@interface AboutTableViewController : UITableViewController <
KGORequestDelegate, MFMailComposeViewControllerDelegate> {
    
    BOOL showBuildNumber;
    
    NSArray * resultArray;
    
    UIView * loadingView;
}

@property (nonatomic, retain) KGORequest * request;
@property (nonatomic, retain) ModuleTag * moduleTag;
@property (nonatomic, retain) NSArray * resultArray;

@property (nonatomic, retain) UIView * loadingView;

- (void) addLoadingView;
- (void) removeLoadingView; 

@end
