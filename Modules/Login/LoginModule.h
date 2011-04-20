#import "KGOModule.h"
#import "KGOWebViewController.h"

@interface LoginModule : KGOModule <KGOWebViewControllerDelegate> {

}

@property(nonatomic, retain) NSString *username;
@property(nonatomic, retain) NSString *userDescription;

- (UIView *)currentUserWidget;

@end
