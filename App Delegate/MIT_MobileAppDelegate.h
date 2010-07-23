#import <UIKit/UIKit.h>

@class MITModule;
@class SpringboardViewController;
@class ModoNavigationController;

// subclass UIWindow to receive shake events
@interface MotionDetectorWindow : UIWindow {
}

@end

@interface MIT_MobileAppDelegate : NSObject <UIApplicationDelegate> {
    
    MotionDetectorWindow *window;
    ModoNavigationController *theNavController;
    SpringboardViewController *theSpringboard;
    UIViewController *appModalHolder;
    
    NSArray *modules; // all registered modules as defined in MITModuleList.m
    NSData *devicePushToken; // deviceToken returned by Apple's push servers when we register. Will be nil if not available.
    
    NSInteger networkActivityRefCount; // the number of concurrent network connections the user should know about. If > 0, spinny in status bar is shown
}

- (void)showNetworkActivityIndicator;
- (void)hideNetworkActivityIndicator;

- (void)presentAppModalViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)dismissAppModalViewControllerAnimated:(BOOL)animated;

@property (nonatomic, retain) IBOutlet MotionDetectorWindow *window;
@property (nonatomic, retain) ModoNavigationController *theNavController;
@property (nonatomic, retain) NSArray *modules;
@property (nonatomic, retain) NSData *deviceToken;

@end

@interface APNSUIDelegate : NSObject <UIAlertViewDelegate>
{
	NSDictionary *apnsDictionary;
	MIT_MobileAppDelegate *appDelegate;
}

- (id) initWithApnsDictionary: (NSDictionary *)apns appDelegate: (MIT_MobileAppDelegate *)delegate;

@end

