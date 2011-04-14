#import <UIKit/UIKit.h>
#import "KGORequestManager.h"
#import <MessageUI/MFMailComposeViewController.h>

@interface AboutTableViewController : UITableViewController <
KGORequestDelegate, MFMailComposeViewControllerDelegate> {
    
    BOOL showBuildNumber;
    
    NSString * aboutText;
    NSString * orgText;
    NSString * orgName;
    NSString * orgEmail;
    NSString * orgWebsite;
    NSString * credits;
    NSString * copyright;
}

@property (nonatomic, retain) KGORequest * request;
@property (nonatomic, retain) NSString * moduleTag;

@end
