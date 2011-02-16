#import <UIKit/UIKit.h>

@class KGOModule;

/*
 * this is a substantially rewritten version of KGOAppDelegate
 * modified primarily for simultaneous iPhone/iPad targeting
 */
@interface KGOAppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate> {
    
    UIWindow *window;
    UINavigationController *theNavController;
    UIViewController *appModalHolder;
    
    NSDictionary *_appConfig;
    
    NSArray *_modules; // all registered modules as defined in Config.plist
    KGOModule *_visibleModule;

    NSInteger networkActivityRefCount; // the number of concurrent network connections the user should know about. If > 0, spinny in status bar is shown
    
    NSData *devicePushToken; // deviceToken returned by Apple's push servers when we register. Will be nil if not available.
    NSMutableArray *_unreadNotifications;
    BOOL showingAlertView;
}

- (void)showNetworkActivityIndicator;
- (void)hideNetworkActivityIndicator;

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) UINavigationController *theNavController;
@property (nonatomic, retain) NSData *deviceToken;

@property (nonatomic, readonly) NSArray *modules;
@property (nonatomic, readonly) NSDictionary *appConfig;

@end

@interface KGOAppDelegate (URLHandlers)

- (BOOL)handleInternalURL:(NSURL *)url;
- (BOOL)handleFacebookURL:(NSURL *)url;

@end



// TODO: add arguments for different modal styles for ipad
@interface KGOAppDelegate (AppModalViewController)

- (void)setupAppModalHolder;
- (void)presentAppModalViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)dismissAppModalViewControllerAnimated:(BOOL)animated;

@end


@interface KGOAppDelegate (Notifications)

- (void)registerForRemoteNotifications:(NSDictionary *)launchOptions;
- (void)updateNotificationUI;
- (void)saveUnreadNotifications;

@property (nonatomic, readonly) NSMutableArray *unreadNotifications;

@end


