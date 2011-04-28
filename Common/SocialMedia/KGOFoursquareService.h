#import <Foundation/Foundation.h>
#import "KGOSocialMediaService.h"

@class KGOFoursquareEngine;

@interface KGOFoursquareService : NSObject <KGOSocialMediaService> {
    
    KGOFoursquareEngine *_foursquareEngine;
    NSInteger _foursquareStartupCount;
    
    NSString *_clientID;
    NSString *_clientSecret;
}

- (KGOFoursquareEngine *)foursquareEngine;
- (void)didReceiveFoursquareAuthCode:(NSString *)code;

@end
