#import <Foundation/Foundation.h>
#import "KGOSocialMediaService.h"
//#import "MGTwitterEngine.h"
#import "TwitterViewControllerDelegate.h"

extern NSString * const TwitterUsernameKey;

@interface KGOTwitterService : NSObject <KGOSocialMediaService,
//MGTwitterEngineDelegate, 
TwitterViewControllerDelegate, UIAlertViewDelegate> {
    
    NSString *_oauthKey;
    NSString *_oauthSecret;
	
    NSInteger _twitterStartupCount;
	//MGTwitterEngine *_twitterEngine;
	NSString *_twitterUsername;
    NSString *_twitterPassword;
    
    id _lastTarget;
    SEL _lastSuccessAction;
    SEL _lastFailureAction;
    NSString *_lastConnectionIdentifier;
    
}

@property (nonatomic, retain) NSString *twitterUsername;

- (void)loginTwitterWithUsername:(NSString *)username password:(NSString *)password;
- (NSString *)twitterUsername;
- (void)setTwitterUsername:(NSString *)username;
- (void)postToTwitter:(NSString *)text;
- (void)postToTwitter:(NSString *)text target:(id)target success:(SEL)successAction failure:(SEL)failureAction;
- (void)disconnectTarget:(id)target;

@end
