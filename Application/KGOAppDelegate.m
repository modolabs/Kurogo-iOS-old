#import "KGOAppDelegate.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOModule.h"
#import "AnalyticsWrapper.h"
#import "KGOSocialMediaController.h"
#import "KGORequestManager.h"
#import "Foundation+KGOAdditions.h"

@implementation KGOAppDelegate

@synthesize window = _window, timeZone;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    _navigationStyle = KGONavigationStyleUnknown;
    
    networkActivityRefCount = 0;
    showingAlertView = NO;
    
    _modulesByTag = [[NSMutableDictionary alloc] init];
    _modules = [[NSMutableArray alloc] init];
    
    [[KGORequestManager sharedManager] requestSessionInfo];
    [self loadHomeModule];
    [self loadNavigationContainer]; // adds theNavController.view to self.window

    // refresh social media settings as modules get added
    // TODO: rename -loadSocialMediaController so it doesn't look like a method
    // that creates new references
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadSocialMediaController)
                                                 name:ModuleListDidChangeNotification
                                               object:nil];
    
    self.window.backgroundColor = [UIColor blackColor]; // necessary for horizontal flip transitions -- background shows through
    [self.window makeKeyAndVisible];
    
    [[AnalyticsWrapper sharedWrapper] setup];

    [self registerForRemoteNotifications:launchOptions];
    
    [self loadModules];

    return YES;
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
        [aModule becomeInactive];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_appConfig release];
    [_unreadNotifications release];
    [_modules release];
	[_window release];
	[super dealloc];
}

@end


