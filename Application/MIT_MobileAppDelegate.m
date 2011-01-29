#import "MIT_MobileAppDelegate.h"
#import "MITModuleList.h"
#import "MITModule.h"
//#import "MITDeviceRegistration.h"
//#import "MITUnreadNotifications.h"
//#import "AudioToolbox/AudioToolbox.h"
#import "SpringboardViewController.h"
#import "AnalyticsWrapper.h"

@implementation MIT_MobileAppDelegate

@synthesize window, modules;
@synthesize deviceToken = devicePushToken;
@synthesize theNavController;
@synthesize springboard = theSpringboard;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    networkActivityRefCount = 0;
    
    // Initialize all modules
    self.modules = [self createModules]; // -createModules defined in ModuleListAdditions category
    
    [self registerDefaultModuleOrder];
    [self loadSavedModuleOrder];
    
	// set modules state
	NSDictionary *modulesState = [[NSUserDefaults standardUserDefaults] objectForKey:MITModulesSavedStateKey];
	for (MITModule *aModule in self.modules) {
		NSDictionary *pathAndQuery = [modulesState objectForKey:aModule.tag];
		aModule.currentPath = [pathAndQuery objectForKey:@"path"];
		aModule.currentQuery = [pathAndQuery objectForKey:@"query"];
	}
	
	//APNS dictionary generated from the json of a push notificaton
	NSDictionary *apnsDict = [launchOptions objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"];
	if (!apnsDict) {
		// application was not opened in response to a notification
		// so do the regular load process
		[self loadActiveModule];
	}
    
    // Set up window
    self.springboard = [[SpringboardViewController alloc] initWithNibName:nil bundle:nil];
    theNavController = [[ModoNavigationController alloc] initWithRootViewController:self.springboard];
    theNavController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];
    [self.window addSubview:theNavController.view];
    
    appModalHolder = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    appModalHolder.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    appModalHolder.view.userInteractionEnabled = NO;
    appModalHolder.view.hidden = YES;
    [self.window addSubview:appModalHolder.view];

    self.window.backgroundColor = [UIColor blackColor]; // necessary for horizontal flip transitions -- background shows through
    [self.window makeKeyAndVisible];

    // Override point for customization after view hierarchy is set
    for (MITModule *aModule in self.modules) {
        [aModule applicationDidFinishLaunching];
    }
    
    // set up analytics
    [[AnalyticsWrapper sharedWrapper] setupWithProvider:ModoAnalyticsProviderGoogle];

    /*
    // Register for push notifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    // get deviceToken if it exists
    self.deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"MITDeviceToken"];
	
	[MITUnreadNotifications updateUI];
	[MITUnreadNotifications synchronizeWithMIT];
	
	// check if application was opened in response to a notofication
	if(apnsDict) {
		MITNotification *notification = [MITUnreadNotifications addNotification:apnsDict];
		[[self moduleForTag:notification.moduleName] handleNotification:notification appDelegate:self shouldOpen:YES];
		NSLog(@"Application opened in response to notification=%@", notification);
	}	
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(returnToHome) name:@"shake" object:nil];
    */
    return YES;
}

// Because we implement -application:didFinishLaunchingWithOptions: this only gets called when an mitmobile:// URL is opened from within this app
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
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
        MITModule *module = [self moduleForTag:moduleTag];
        if ([path rangeOfString:@"/"].location == 0) {
            path = [path substringFromIndex:1];
        }
        
        // right now expecting URLs like mitmobile://people/search?Some%20Guy
        NSString *query = [[url query] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
		module.hasLaunchedBegun = YES;
        canHandle = [module handleLocalPath:path query:query];
    } else {
        DLog(@"%s couldn't handle url: %@", _cmd, url);
    }

    return canHandle;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[AnalyticsWrapper sharedWrapper] shutdown];
    
    // Let each module perform clean up as necessary
    for (MITModule *aModule in self.modules) {
        [aModule applicationWillTerminate];
    }
    
	[self saveModulesState];
    [self saveModuleOrder];
    // Save preferences
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    [self.deviceToken release];
    [self.modules release];
    [self.springboard release];
	[window release];
	[super dealloc];
}

#pragma mark -
#pragma mark Shared resources

- (void)showNetworkActivityIndicator {
    networkActivityRefCount++;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
//    NSLog(@"network indicator ++ %d", networkActivityRefCount);
}

- (void)hideNetworkActivityIndicator {
    if (networkActivityRefCount > 0) {
        networkActivityRefCount--;
//        NSLog(@"network indicator -- %d", networkActivityRefCount);
    }
    if (networkActivityRefCount == 0) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
//        NSLog(@"network indicator off");
    }
}

#pragma mark -
#pragma mark App-modal view controllers

// Call these instead of [theNavigationController presentModal...]
// because the default behavior hides the view controller behind, in case we want transparent modal views.
- (void)presentAppModalViewController:(UIViewController *)viewController animated:(BOOL)animated {
    appModalHolder.view.hidden = NO;
    [appModalHolder presentModalViewController:viewController animated:animated];
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

/*
#pragma mark -
#pragma mark Push notifications

- (void)application:(UIApplication *)application 
didReceiveRemoteNotification:(NSDictionary *)userInfo {
	[MITUnreadNotifications updateUI];
	
	// vibrate the phone
	AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
	
	// display the notification in an alert
	UIAlertView *notificationView =[[UIAlertView alloc]
		initWithTitle:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]  
		message:[[userInfo objectForKey:@"aps"] objectForKey:@"alert"]
		delegate:[[[APNSUIDelegate alloc] initWithApnsDictionary:userInfo appDelegate:self] autorelease]
		cancelButtonTitle:@"Close"
		otherButtonTitles:@"View", nil];
	[notificationView show];
	[notificationView release];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	NSLog(@"Registered for push notifications. deviceToken == %@", deviceToken);
    self.deviceToken = deviceToken;
    
	MITIdentity *identity = [MITDeviceRegistration identity];
	if(!identity) {
		[MITDeviceRegistration registerNewDeviceWithToken:deviceToken];
	} else {
		NSData *oldToken = [[NSUserDefaults standardUserDefaults] objectForKey:DeviceTokenKey];
		
		if(![oldToken isEqualToData:deviceToken]) {
			[MITDeviceRegistration newDeviceToken:deviceToken];
		}
	}
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Failed to register for remote notifications. Error: %@", error);
	MITIdentity *identity = [MITDeviceRegistration identity];
	if(!identity) {
		[MITDeviceRegistration registerNewDeviceWithToken:nil];
	}
}

@end



@implementation APNSUIDelegate

- (id) initWithApnsDictionary: (NSDictionary *)apns appDelegate: (MIT_MobileAppDelegate *)delegate;
{
	self = [super init];
	if (self != nil) {
		apnsDictionary = [apns retain];
		appDelegate = [delegate retain];
		[self retain]; // releases when delegate method called
	}
	return self;
}

- (void) dealloc {
	[apnsDictionary release];
	[super dealloc];
}

// this is the delegate method for responding to the push notification UIAlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	MITNotification *notification = [MITUnreadNotifications addNotification:apnsDictionary];
	[[appDelegate moduleForTag:notification.moduleName] handleNotification:notification appDelegate:appDelegate shouldOpen:(buttonIndex == 1)];
	
	[self release];
}
*/
@end

@implementation MotionDetectorWindow

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if ((motion == UIEventSubtypeMotionShake) &&
		([[NSUserDefaults standardUserDefaults] boolForKey:ShakeToReturnPrefKey])) {
			
        MIT_MobileAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        [appDelegate returnToHome];
    }
}

@end

