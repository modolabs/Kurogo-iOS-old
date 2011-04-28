#import <Foundation/Foundation.h>

/* describes a connection handler to a third party web service that requires
 * user authentication, generally via oauth (but not important).
 * the name assumes this service is some kind of social media, but we may find
 * services later that are not social.
 */

@protocol KGOSocialMediaService <NSObject>

- (id)initWithConfig:(NSDictionary *)config;

- (NSString *)serviceDisplayName;
- (NSString *)userDisplayName;

- (void)startup;
- (void)shutdown;

- (BOOL)isSignedIn;
- (void)signin;  // return true if signin process initiated properly
- (void)signout; // post a notification when signout is complete

@optional

- (void)addOptions:(NSArray *)options forSetting:(NSString *)setting;

@end
