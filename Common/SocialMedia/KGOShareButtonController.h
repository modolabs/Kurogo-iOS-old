#import <UIKit/UIKit.h>
#import "FBConnect.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "KGOSocialMediaController.h"

typedef enum {
    KGOShareControllerShareTypeEmail = 1,
    KGOShareControllerShareTypeFacebook = 1 << 1,
    KGOShareControllerShareTypeTwitter = 1 << 2
} KGOShareControllerShareType;




@interface KGOShareButtonController : NSObject <UIActionSheetDelegate> {
    
    NSArray *_shareMethods;
    NSUInteger _shareTypes;

}

@property (nonatomic, assign) UIViewController *contentsController;

@property (nonatomic) NSUInteger shareTypes;
@property (nonatomic, retain) NSString *actionSheetTitle;

@property (nonatomic, retain) NSString *shareTitle; // email subject and twitter message
@property (nonatomic, retain) NSString *shareURL;
@property (nonatomic, retain) NSString *shareBody;  // email body

- (id)initWithContentsController:(UIViewController *)controller;

- (void)shareInView:(UIView *)view;

@end
