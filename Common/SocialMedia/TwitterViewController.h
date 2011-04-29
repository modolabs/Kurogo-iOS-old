#import <UIKit/UIKit.h>
#import "MGTwitterEngine.h"
#import "ConnectionWrapper.h"
#import "KGOSocialMediaController.h"
#import "BitlyWrapperDelegate.h"

// TODO: strip this down to handle just the login UI

@protocol TwitterViewControllerDelegate;

@interface TwitterViewController : UIViewController <UITextFieldDelegate, BitlyWrapperDelegate> {
    
    // pre signed-in state. shown by default.
    IBOutlet UIView *_loginContainerView;
    IBOutlet UILabel *_loginHintLabel;
    IBOutlet UITextField *_usernameField;
    IBOutlet UITextField *_passwordField;
    IBOutlet UIButton *_signInButton;

    // loading state. hidden by default.
    IBOutlet UIView *_loadingView;
    IBOutlet UIActivityIndicatorView *_spinnerView;
    
    // message state. hidden by default.
    IBOutlet UIView *_messageContainerView;
    IBOutlet UILabel *_usernameLabel;
    IBOutlet UILabel *_counterLabel;
    IBOutlet UITextView *_messageView;
    IBOutlet UIButton *_tweetButton;
}

- (IBAction)signInButtonPressed:(UIButton *)sender;
- (IBAction)tweetButtonPressed:(id)sender;

- (void)twitterDidLogout:(NSNotification *)aNotification;
- (void)twitterDidLogin:(NSNotification *)aNotification;

@property (nonatomic, retain) NSString *longURL;
@property (nonatomic, retain) NSString *shortURL;
@property (nonatomic, retain) NSString *preCannedMessage;

@property (nonatomic, assign) id<TwitterViewControllerDelegate> delegate;

@end
