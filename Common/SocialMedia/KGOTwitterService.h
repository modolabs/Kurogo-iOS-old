#import <Foundation/Foundation.h>
#import "KGOSocialMediaService.h"
#import "MGTwitterEngine.h"
#import "TwitterViewControllerDelegate.h"

@interface KGOTwitterService : NSObject <KGOSocialMediaService,
MGTwitterEngineDelegate, TwitterViewControllerDelegate> {
    
    NSString *_oauthKey;
    NSString *_oauthSecret;
	
    NSInteger _twitterStartupCount;
	MGTwitterEngine *_twitterEngine;
	NSString *_twitterUsername;
    NSString *_twitterPassword;
    
}

@property (nonatomic, retain) NSString *twitterUsername;

- (void)loginTwitterWithUsername:(NSString *)username password:(NSString *)password;
- (NSString *)twitterUsername;
- (void)setTwitterUsername:(NSString *)username;
- (void)postToTwitter:(NSString *)text;

@end
