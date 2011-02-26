/* AnalyticsWrapper.h
 * This tracker is not thread safe.
 */

#import <Foundation/Foundation.h>
#import "GANTracker.h"

typedef enum {
    KGOAnalyticsProviderNone,
    KGOAnalyticsProviderGoogle,
} KGOAnalyticsProvider;


@interface AnalyticsWrapper : NSObject <GANTrackerDelegate> {
    
	NSDictionary *_preferences;
    KGOAnalyticsProvider _provider;

}

+ (AnalyticsWrapper *)sharedWrapper;
- (void)shutdown;

// this will change
- (void)setup;

// these will probably change
- (void)trackPageview:(NSString *)pageID;
- (void)trackEvent:(NSString *)event action:(NSString *)action label:(NSString *)label;

@property KGOAnalyticsProvider provider;

@end
