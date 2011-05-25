#import <UIKit/UIKit.h>

#define KGO_SHARED_APP_DELEGATE() (KGOAppDelegate *)[[UIApplication sharedApplication] delegate]

// the config strings for these are List, Grid, Portlet, Sidebar, and SplitView.
// TODO: make these options more visible
typedef enum {
    KGONavigationStyleUnknown,
    KGONavigationStyleTableView,
    KGONavigationStyleIconGrid,
    KGONavigationStylePortlet,
    // the following are not enabled for iPhone
    KGONavigationStyleTabletSidebar,
    KGONavigationStyleTabletSplitView
} KGONavigationStyle;

@class KGOModule;

/*
 * this is a substantially rewritten version of KGOAppDelegate
 * modified primarily for simultaneous iPhone/iPad targeting
 */
@interface KGOAppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate> {
    
    UIWindow *window;
    UINavigationController *_appNavController;
    UIViewController *_appHomeScreen;
    UIViewController *_visibleViewController;
    KGONavigationStyle _navigationStyle;
    
    NSDictionary *_appConfig;
    
    NSMutableDictionary *_modulesByTag;
    NSMutableArray *_modules;
    KGOModule *_visibleModule;

    NSInteger networkActivityRefCount; // the number of concurrent network connections the user should know about. If > 0, spinny in status bar is shown

    // push notifications
    NSData *_deviceToken; // 
    NSMutableArray *_unreadNotifications;
    BOOL showingAlertView;
}

- (void)showNetworkActivityIndicator;
- (void)hideNetworkActivityIndicator;

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, readonly) NSArray *modules;
@property (nonatomic, readonly) NSDictionary *appConfig;

@end

@interface KGOAppDelegate (URLHandlers)

- (NSString *)defaultURLScheme;
- (BOOL)handleInternalURL:(NSURL *)url;
- (BOOL)handleFacebookURL:(NSURL *)url;

@end

@interface KGOAppDelegate (Notifications)

- (void)registerForRemoteNotifications:(NSDictionary *)launchOptions;
- (void)updateNotificationUI;
- (void)saveUnreadNotifications;

@property (nonatomic, readonly) NSMutableArray *unreadNotifications;

@end


