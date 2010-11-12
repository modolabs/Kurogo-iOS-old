#import "AnalyticsWrapper.h"


@implementation AnalyticsWrapper

@synthesize provider = _provider;

static AnalyticsWrapper *s_sharedWrapper = nil;

+ (AnalyticsWrapper *)sharedWrapper {
    if (s_sharedWrapper == nil) {
        s_sharedWrapper = [[AnalyticsWrapper alloc] init];
    }
    return s_sharedWrapper;
}

- (id)init {
    if (self = [super init]) {
        _provider = ModoAnalyticsProviderGoogle;
    }
    return self;
}


- (void)setupWithProvider:(ModoAnalyticsProvider)provider {
    self.provider = provider;
    switch (provider) {
        case ModoAnalyticsProviderGoogle:
        default:
            // TODO: figure out reasonable dispatch time interval
            [[GANTracker sharedTracker] startTrackerWithAccountID:AnalyticsAccountID
                                                   dispatchPeriod:30
                                                         delegate:self];
            break;
    }
}

- (void)shutdown {
    [[GANTracker sharedTracker] stopTracker];
}

- (void)trackPageview:(NSString *)pageID {
    NSError *error = nil;
    // TODO: GA requires page views to begin with a slash
    // may want to add that into this function
    if (![[GANTracker sharedTracker] trackPageview:pageID
                                         withError:&error])
    {
        NSLog(@"Failed to track pageview: %@", [error description]);

        // TODO: handle error
    }
}

- (void)trackEvent:(NSString *)event action:(NSString *)action label:(NSString *)label {
    NSError *error = nil;
    if (![[GANTracker sharedTracker] trackEvent:event  // required
                                         action:action // required
                                          label:label  // can be nil
                                          value:-1     // -1 for no value
                                      withError:&error])
    {
        NSLog(@"Failed to track event: %@", [error description]);
        
        // TODO: handle error
    }
}


#pragma mark Google Analytics Delegation

- (void)trackerDispatchDidComplete:(GANTracker *)tracker
                  eventsDispatched:(NSUInteger)eventsDispatched
              eventsFailedDispatch:(NSUInteger)eventsFailedDispatch
{
    NSLog(@"%d events dispatched, %d events failed to dispatch", eventsDispatched, eventsFailedDispatch);
    
    
    // TODO: figure out what to do about successful and failed event dispatches
}

@end
