#import "AnalyticsWrapper.h"
#import "KGOAppDelegate.h"

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
    self = [super init];
    if (self) {
        NSDictionary *infoDict = [(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] appConfig];
		_preferences = [[infoDict objectForKey:@"Analytics"] retain];
        _provider = KGOAnalyticsProviderNone;
    }
    return self;
}


- (void)setup {
	NSString *provider = [_preferences objectForKey:@"Provider"];
	NSString *accountID = [_preferences objectForKey:@"AccountID"];
	
	if ([provider isEqualToString:@"Google"] && [accountID length]) {
		_provider = KGOAnalyticsProviderGoogle;
		
		// TODO: figure out reasonable dispatch time interval
		[[GANTracker sharedTracker] startTrackerWithAccountID:accountID
											   dispatchPeriod:30
													 delegate:self];
	}
}

- (void)shutdown {
	switch (_provider) {
		case KGOAnalyticsProviderGoogle:
			[[GANTracker sharedTracker] stopTracker];
			break;
		default:
			break;
	}
}

- (void)trackPageview:(NSString *)pageID {
	switch (_provider) {
		case KGOAnalyticsProviderGoogle:
		{
			NSError *error = nil;
			// TODO: GA requires page views to begin with a slash
			// may want to add that into this function
			if (![[GANTracker sharedTracker] trackPageview:pageID
												 withError:&error])
			{
				NSLog(@"Failed to track pageview: %@", [error description]);
				
				// TODO: handle error
			}
			break;
		}
		default:
			break;
	}
}

- (void)trackEvent:(NSString *)event action:(NSString *)action label:(NSString *)label {
	switch (_provider) {
		case KGOAnalyticsProviderGoogle:
		{
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
			break;
		}
		default:
			break;
	}
}


#pragma mark Google Analytics Delegation

- (void)trackerDispatchDidComplete:(GANTracker *)tracker
                  eventsDispatched:(NSUInteger)eventsDispatched
              eventsFailedDispatch:(NSUInteger)eventsFailedDispatch
{
    NSLog(@"Google Analytics: %d events dispatched, %d events failed to dispatch", eventsDispatched, eventsFailedDispatch);
    
    
    // TODO: figure out what to do about successful and failed event dispatches
}

@end
