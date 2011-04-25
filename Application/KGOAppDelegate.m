#import "KGOAppDelegate.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOModule.h"
#import "KGONotification.h"
#import "AudioToolbox/AudioToolbox.h"
#import "AnalyticsWrapper.h"
#import "KGOSocialMediaController.h"
#import "KGORequestManager.h"
#import "Foundation+KGOAdditions.h"

@implementation KGOAppDelegate

@synthesize window, modules = _modules;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    _navigationStyle = KGONavigationStyleUnknown;
    
    networkActivityRefCount = 0;
    showingAlertView = NO;
    
    [[KGORequestManager sharedManager] requestSessionInfo];
    [self loadHomeModule];
    [self loadNavigationContainer]; // adds theNavController.view to self.window
    [self loadSocialMediaController]; // initializes social media settings
    
    self.window.backgroundColor = [UIColor blackColor]; // necessary for horizontal flip transitions -- background shows through
    [self.window makeKeyAndVisible];
    
    [[AnalyticsWrapper sharedWrapper] setup];

    [self registerForRemoteNotifications:launchOptions];
    
    [self loadModules];

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {

    NSLog(@"attempting to handle URL %@\nsource application: %@\nannotation: %@", [url description], [sourceApplication description], [annotation description]);
    
    BOOL canHandle = NO;

    NSString *urlKey = nil;
    NSString *scheme = [url scheme];
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSArray *urlTypes = [infoDict objectForKey:@"CFBundleURLTypes"];
    for (NSDictionary *type in urlTypes) {
        urlKey = [type objectForKey:@"CFBundleURLName"];
        NSArray *schemes = [type objectForKey:@"CFBundleURLSchemes"];
        for (NSString *supportedScheme in schemes) {
            if ([supportedScheme isEqualToString:scheme]) {
                canHandle = YES;
                break;
            }
        }
        if (canHandle) {
            break;
        }
    }
    
    if (canHandle) {
        if ([urlKey isEqualToString:@"com.facebook"]) {
            canHandle = [self handleFacebookURL:url];
        } else {
            canHandle = [self handleInternalURL:url];
        }
        
    } else {
        DLog(@"%s couldn't handle url: %@", _cmd, url);
    }
    
    return canHandle;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[AnalyticsWrapper sharedWrapper] shutdown];
    
    // Let each module perform clean up as necessary
    for (KGOModule *aModule in self.modules) {
        [aModule terminate];
        [aModule applicationWillTerminate];
    }
    
    // Save preferences
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    for (KGOModule *aModule in self.modules) {
        [aModule willBecomeDormant];
        [aModule applicationDidEnterBackground];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    for (KGOModule *aModule in self.modules) {
        [aModule applicationWillEnterForeground];
    }
}
/*
- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationSignificantTimeChange:(UIApplication *)application {
}

#pragma mark Protected data

- (void)applicationProtectedDataWillBecomeUnavailable:(UIApplication *)application {
}

- (void)applicationProtectedDataDidBecomeAvailable:(UIApplication *)application {
}
*/
#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    for (KGOModule *aModule in self.modules) {
        // TODO: check whether the module is being used, if not send 
        // a -terminate message
        [aModule didReceiveMemoryWarning];
    }
}

- (void)dealloc {
    [_appConfig release];
    [_unreadNotifications release];
    [_modules release];
	[window release];
	[super dealloc];
}

#pragma mark -
#pragma mark Shared resources

- (NSDictionary *)appConfig {
    if (!_appConfig) {
        NSString * mainFile = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"];
        NSString * secretFile = [[NSBundle mainBundle] pathForResource:@"secret/Config" ofType:@"plist"];
        if (!secretFile) {
            _appConfig = [[NSDictionary alloc] initWithContentsOfFile:mainFile];
        } else {
            NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithContentsOfFile:mainFile];
            NSDictionary *overrides = [NSDictionary dictionaryWithContentsOfFile:secretFile];
            for (id aKey in [overrides allKeys]) {
                [mutableDict setObject:[overrides objectForKey:aKey] forKey:aKey];
            }
            _appConfig = [mutableDict copy];
        }
        NSLog(@"%@", [_appConfig description]);
    }
    return _appConfig;
}

- (void)showNetworkActivityIndicator {
    networkActivityRefCount++;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    DLog(@"network indicator ++ %d", networkActivityRefCount);
}

- (void)hideNetworkActivityIndicator {
    if (networkActivityRefCount > 0) {
        networkActivityRefCount--;
        NSLog(@"network indicator -- %d", networkActivityRefCount);
    }
    if (networkActivityRefCount == 0) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
}

#pragma mark -
#pragma mark Notification delegation

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	DLog(@"Registered for push notifications. deviceToken == %@", deviceToken);
    KGORequestManager *requestManager = [KGORequestManager sharedManager];
    if (![requestManager.devicePushToken isEqualToData:deviceToken]) {
        requestManager.devicePushToken = deviceToken;
        [requestManager registerNewDeviceToken];
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Failed to register for remote notifications. Error: %@", error);
}

// TODO: decide if we want to keep the following behavior, which only runs
// while the app is open and thus seems pretty redundant
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	// vibrate the phone
	AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    
	KGONotification *notification = [KGONotification notificationWithDictionary:userInfo];
    [_unreadNotifications addObject:notification];

	// display the notification in an alert
    if (!showingAlertView) {
        showingAlertView = YES;

        NSString *appDisplayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        // TODO: figure out if it's really necessary to construct this alert view
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:appDisplayName
                                                            message:[[userInfo objectForKey:@"aps"] objectForKey:@"alert"]
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Close", nil)
                                                  otherButtonTitles:NSLocalizedString(@"View", nil), nil] autorelease];
        [alertView show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    KGONotification *latestNotification = [_unreadNotifications lastObject];
	
    KGOModule *module = [self moduleForTag:latestNotification.moduleName];
	[module handleNotification:latestNotification];

    NSString *viewTitle = NSLocalizedString(@"View", nil);
    
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:viewTitle]) {
        [module willBecomeVisible];
        // TODO: show the module
    }
    
    showingAlertView = NO;
}

@end

#pragma mark -

@implementation KGOAppDelegate (URLHandlers)

- (NSString *)defaultURLScheme
{
    static NSString *internalScheme = nil;

    if (internalScheme == nil) {
        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
        NSArray *urlTypes = [infoDict objectForKey:@"CFBundleURLTypes"];
        NSString *bundleID = [infoDict objectForKey:@"CFBundleIdentifier"];
        
        for (NSDictionary *type in urlTypes) {
            NSString *urlKey = [type objectForKey:@"CFBundleURLName"];
            if ([urlKey isEqualToString:bundleID]) {
                NSArray *schemes = [type objectForKey:@"CFBundleURLSchemes"];
                if (schemes.count) {
                    internalScheme = [schemes objectAtIndex:0];
                }
                break;
            }
        }
    }

    return internalScheme;
}

- (BOOL)handleFacebookURL:(NSURL *)url
{
    // TODO: make sure this balances out
    DLog(@"is facebook started?");
    [[KGOSocialMediaController sharedController] startupFacebook];
    [[KGOSocialMediaController sharedController] parseCallbackURL:url];
    
    return [[KGOSocialMediaController sharedController] isFacebookLoggedIn];
}

- (BOOL)handleInternalURL:(NSURL *)url {
    NSString *path = [url path];
    NSString *moduleTag = [url host];
    KGOModule *module = [self moduleForTag:moduleTag];
    if ([path rangeOfString:@"/"].location == 0) {
        path = [path substringFromIndex:1];
    }
    
    // right now expecting URLs like mitmobile://people/search?Some%20Guy
    NSString *query = [[url query] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    return [module handleLocalPath:path query:query];
}

@end

#pragma mark -

@implementation KGOAppDelegate (Notifications)

- (void)registerForRemoteNotifications:(NSDictionary *)launchOptions {
    // Register for push notifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
	
	[self updateNotificationUI];
	//[self updateNotificationServer];
	
	// check if application was opened in response to a notofication
	NSDictionary *apnsDict = [launchOptions objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"];
	if (apnsDict) {
		KGONotification *notification = [KGONotification notificationWithDictionary:apnsDict];
        [_unreadNotifications addObject:notification];
        
        KGOModule *module = [self moduleForTag:notification.moduleName];
		[module handleNotification:notification];
        [module willBecomeVisible];
		NSLog(@"Application opened in response to notification=%@", notification);
	}	
}

- (void)updateNotificationUI {
	NSNumber *badgeCount = nil;
	int badgeCountInt = 0;
	
	NSMutableDictionary *notificationsByModule = [NSMutableDictionary dictionary];
	NSArray *notifications = [self unreadNotifications];

	for (KGONotification *notification in notifications) {
        badgeCount = [notificationsByModule objectForKey:notification.moduleName];
		if(badgeCount) {
			badgeCountInt = [badgeCount intValue] + 1;
		} else {
			badgeCountInt = 1;
		}
		
		[notificationsByModule setObject:[NSNumber numberWithInt:badgeCountInt] forKey:notification.moduleName];
	}
    
	// update the badge values for each tab item
	for (KGOModule *module in self.modules) {
		NSNumber *badgeValue = [notificationsByModule objectForKey:module.tag];
		NSString *badgeString = nil;
		if(badgeValue) {
			badgeString = [badgeValue description];
		}
		[module setBadgeValue:badgeString];
	}
	
	// update the total badge value for the application
	[UIApplication sharedApplication].applicationIconBadgeNumber = [notifications count];
}

- (NSMutableArray *)unreadNotifications {
    return _unreadNotifications;
}

- (void)fetchUnreadNotificationsFromCache {
    if (!_unreadNotifications) {
        _unreadNotifications = [[NSMutableArray alloc] init];
        for (NSDictionary *aDictionary in [[NSUserDefaults standardUserDefaults] objectForKey:UnreadNotificationsKey]) {
            [_unreadNotifications addObject:[KGONotification notificationWithDictionary:aDictionary]];
        }
    }
}

- (void)saveUnreadNotifications {
	NSMutableArray *arrayToSave = [NSMutableArray arrayWithCapacity:[_unreadNotifications count]];
    for (KGONotification *aNotification in _unreadNotifications) {
        [arrayToSave addObject:aNotification.userInfo];
    }
	[[NSUserDefaults standardUserDefaults] setObject:arrayToSave forKey:UnreadNotificationsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end


