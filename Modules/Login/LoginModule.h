#import "KGOModule.h"
#import "KGORequestManager.h"

@interface LoginModule : KGOModule <KGORequestDelegate> {
    
    NSString *_userName;
    NSString *_userClass;
    
    KGORequest *_sessionInfoRequest;
}

- (void)userDidLogin;

@end
