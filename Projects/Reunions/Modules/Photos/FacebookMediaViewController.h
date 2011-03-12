#import <UIKit/UIKit.h>
#import "FBConnect.h"


@interface FacebookMediaViewController : UIViewController <UIWebViewDelegate> {
    
    IBOutlet UISegmentedControl *_filterControl;
    IBOutlet UIWebView *_signedInUserView;
    IBOutlet UIScrollView *_scrollView;
    
    // hidden for logged-in users
    IBOutlet UIView *_loginView;
    IBOutlet UILabel *_loginHintLabel;
    IBOutlet UIButton *_loginButton; // login or open facebook

    FBRequest *_groupsRequest;
    NSString *_groupID;
}

- (IBAction)filterValueChanged:(UISegmentedControl *)sender;
- (IBAction)loginButtonPressed:(UIButton *)sender;

- (void)showLoginView;
- (void)hideLoginView;

- (void)didReceiveGroups:(id)result;
- (void)didReceiveFeed:(id)result;

@end
