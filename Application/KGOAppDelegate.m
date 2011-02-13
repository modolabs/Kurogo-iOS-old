#import "KGOAppDelegate.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOModule.h"
#import "KGONotification.h"
#import "AudioToolbox/AudioToolbox.h"
#import "SpringboardViewController.h"
#import "AnalyticsWrapper.h"

@implementation KGOAppDelegate

@synthesize window, modules = _modules;
@synthesize deviceToken = devicePushToken;
@synthesize theNavController;
@synthesize springboard = theSpringboard;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    networkActivityRefCount = 0;
    showingAlertView = NO;
    
    [self loadModules];
    
    for (KGOModule *aModule in self.modules) {
        [aModule applicationDidFinishLaunching];
    }
    
    [self loadNavigationContainer]; // adds theNavController.view to self.window
    
    [self setupAppModalHolder];  // adds appModalHolder.view to self.window

    self.window.backgroundColor = [UIColor blackColor]; // necessary for horizontal flip transitions -- background shows through
    [self.window makeKeyAndVisible];
    
    [[AnalyticsWrapper sharedWrapper] setup];

    [self registerForRemoteNotifications:launchOptions];

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // TODO: handle incoming URL from facebook SSO
    
    BOOL canHandle = NO;
    
    NSString *scheme = [url scheme];
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSArray *urlTypes = [infoDict objectForKey:@"CFBundleURLTypes"];
    for (NSDictionary *type in urlTypes) {
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
        NSString *path = [url path];
        NSString *moduleTag = [url host];
        KGOModule *module = [self moduleForTag:moduleTag];
        if ([path rangeOfString:@"/"].location == 0) {
            path = [path substringFromIndex:1];
        }
        
        // right now expecting URLs like mitmobile://people/search?Some%20Guy
        NSString *query = [[url query] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
		//module.hasLaunchedBegun = YES;
        canHandle = [module handleLocalPath:path query:query];
    } else {
        DLog(@"%s couldn't handle url: %@", _cmd, url);
    }
    
    return canHandle;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[AnalyticsWrapper sharedWrapper] shutdown];
    
    // Let each module perform clean up as necessary
    for (KGOModule *aModule in self.modules) {
        [aModule applicationWillTerminate];
        [aModule terminate];
    }
    
    // Save preferences
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    for (KGOModule *aModule in self.modules) {
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
        [aModule didReceiveMemoryWarning];
    }
}

- (void)dealloc {
    [self.deviceToken release];
    [self.modules release];
    [self.springboard release];
	[window release];
	[super dealloc];
}

#pragma mark -
#pragma mark Shared resources

- (NSDictionary *)appConfig {
    if (!_appConfig) {
		NSString * file = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"];
        _appConfig = [[NSDictionary alloc] initWithContentsOfFile:file];
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
    self.deviceToken = deviceToken;
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Failed to register for remote notifications. Error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	// vibrate the phone
	AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    
	KGONotification *notification = [KGONotification notificationWithDictionary:userInfo];
    [_unreadNotifications addObject:notification];

	// display the notification in an alert
    if (!showingAlertView) {
        showingAlertView = YES;

        NSString *appDisplayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        UIAlertView *alertView =[[[UIAlertView alloc] initWithTitle:appDisplayName
                                                            message:[[userInfo objectForKey:@"aps"] objectForKey:@"alert"]
                                                           delegate:self
                                                  cancelButtonTitle:@"Close"
                                                  otherButtonTitles:@"View", nil] autorelease];
        [alertView show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    KGONotification *latestNotification = [_unreadNotifications lastObject];
	
    KGOModule *module = [self moduleForTag:latestNotification.moduleName];
	[module handleNotification:latestNotification];

    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"View"]) {
        [module willBecomeVisible];
        // TODO: show the module
    }
    
    showingAlertView = NO;
}

@end

#pragma mark -

@implementation KGOAppDelegate (AppModalViewController)

- (void)setupAppModalHolder {
    appModalHolder = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    appModalHolder.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    appModalHolder.view.userInteractionEnabled = NO;
    appModalHolder.view.hidden = YES;
    [self.window addSubview:appModalHolder.view];
}

// Call these instead of [theNavigationController presentModal...]
// because the default behavior hides the view controller behind, in case we want transparent modal views.
- (void)presentAppModalViewController:(UIViewController *)viewController animated:(BOOL)animated {
	NSLog(@"%@", [viewController description]);
	if (!viewController) return;
	
    appModalHolder.view.hidden = NO;

	if (viewController.navigationController || [viewController isKindOfClass:[UINavigationController class]]) {
		[appModalHolder presentModalViewController:viewController animated:animated];
	} else {
		// since any VC can be presented modally, some will not have nav bars built in
		UINavigationController *navC = [[[UINavigationController alloc] initWithRootViewController:viewController] autorelease];
		viewController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Done"
																							 style:UIBarButtonItemStyleDone
																							target:self
																							action:@selector(dismissAppModalViewController:)] autorelease];
		[appModalHolder presentModalViewController:navC animated:animated];
	}
	
}

- (void)dismissAppModalViewController:(id)sender {
	[self dismissAppModalViewControllerAnimated:YES];
}

- (void)dismissAppModalViewControllerAnimated:(BOOL)animated {
    [appModalHolder dismissModalViewControllerAnimated:animated];
    [self performSelector:@selector(checkIfOkToHideAppModalViewController) withObject:nil afterDelay:0.100];
}

// This is a sad hack for telling when the dismissAppModalViewController animation has completed. It depends on appModalHolder.modalViewController being defined as long as the modal vc is still animating. If Apple ever changes this behavior, the slide-away transition will become a jarring pop.
- (void)checkIfOkToHideAppModalViewController {
    if (!appModalHolder.modalViewController) {
        // allow taps to reach subviews of the tabbar again
        appModalHolder.view.hidden = YES;
    } else {
        [self performSelector:@selector(checkIfOkToHideAppModalViewController) withObject:nil afterDelay:0.100];
    }
}

@end

#pragma mark -


@implementation KGOAppDelegate (Notifications)

- (void)registerForRemoteNotifications:(NSDictionary *)launchOptions {
    // Register for push notifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    // get deviceToken if it exists
    self.deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:DeviceTokenKey];
	
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
		if(badgeCount = [notificationsByModule objectForKey:notification.moduleName]) {
			badgeCountInt = [badgeCount intValue] + 1;
		} else {
			badgeCountInt = 1;
		}
		
		[notificationsByModule setObject:[NSNumber numberWithInt:badgeCountInt] forKey:notification.moduleName];
	}
    
	// update the badge values for each tab item
	for (KGOModule *module in self.modules) {
		NSNumber *badgeValue = nil;
		NSString *badgeString = nil;
		if(badgeValue = [notificationsByModule objectForKey:module.tag]) {
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


