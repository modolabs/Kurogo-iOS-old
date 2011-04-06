#import "KGOModule.h"
//#import "KGORequestManager.h"

@interface LoginModule : KGOModule {// <KGORequestDelegate> {
    
    //KGORequest *_sessionInfoRequest;
}

@property(nonatomic, retain) NSString *username;
@property(nonatomic, retain) NSString *userDescription;

//- (void)userDidLogin;

- (UIView *)currentUserWidget;

@end
