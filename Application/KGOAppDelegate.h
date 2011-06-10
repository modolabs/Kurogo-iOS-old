#import <UIKit/UIKit.h>

@class KGOModule;

@interface KGOAppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate> {
    
    UIWindow *_window;
    UINavigationController *_appNavController;
    UIViewController *_appHomeScreen;
    UIViewController *_visibleViewController;
    KGONavigationStyle _navigationStyle;
    
    NSDictionary *_appConfig;
    
    NSMutableDictionary *_modulesByTag;
    NSMutableArray *_modules;
    KGOModule *_visibleModule;

    // number of concurrent network connections the user should know about. If > 0, spinny in status bar is shown
    NSInteger networkActivityRefCount; 

    // push notifications
    NSData *_deviceToken;
    NSMutableArray *_unreadNotifications;
    BOOL showingAlertView;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end


