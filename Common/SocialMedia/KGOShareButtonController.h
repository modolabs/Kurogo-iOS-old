#import <UIKit/UIKit.h>
#import "FBConnect.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "KGOSocialMediaController.h"

@protocol KGOShareButtonDelegate

- (NSString *)actionSheetTitle;

- (NSString *)emailSubject;
- (NSString *)emailBody;

- (NSString *)fbDialogPrompt;

// TODO: simplify the following...
// currently we are making the delegate do all the work of contstructing
// a JSON string to match the spec at
// http://wiki.developers.facebook.com/index.php/Attachment_%28Streams%29
- (NSString *)fbDialogAttachment;

- (NSString *)twitterUrl;
- (NSString *)twitterTitle;

@optional

@end

// TODO: FacebookWrapperDelegate doesn't work anymore, listen for notifications
@interface KGOShareButtonController : NSObject <UIActionSheetDelegate,
FacebookWrapperDelegate> {

    BOOL loggedIntoFacebook;
	id<KGOShareButtonDelegate> _delegate;

}

@property (nonatomic, assign) id<KGOShareButtonDelegate> delegate;

- (id)initWithDelegate:(id<KGOShareButtonDelegate>)delegate;

- (void)shareInView:(UIView *)view;

- (void)showFacebookDialog;

@end
