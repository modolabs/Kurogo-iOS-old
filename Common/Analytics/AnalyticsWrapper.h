/* AnalyticsWrapper.h
 * This tracker is not thread safe.
 */

#import <Foundation/Foundation.h>
#import "GANTracker.h"

typedef enum {
    ModoAnalyticsProviderGoogle,
} ModoAnalyticsProvider;


@interface AnalyticsWrapper : NSObject <GANTrackerDelegate> {
    
    ModoAnalyticsProvider _provider;

}

+ (AnalyticsWrapper *)sharedWrapper;
- (void)shutdown;

// this will change
- (void)setupWithProvider:(ModoAnalyticsProvider)provider;

// these will probably change
- (void)trackPageview:(NSString *)pageID;
- (void)trackEvent:(NSString *)event action:(NSString *)action label:(NSString *)label;

@property ModoAnalyticsProvider provider;

@end
