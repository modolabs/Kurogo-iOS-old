#import <UIKit/UIKit.h>

@interface KGOSplitViewController : UISplitViewController <UISplitViewControllerDelegate, UIPopoverControllerDelegate> {
    
    UIBarButtonItem *_moduleListButton;
    // TODO: rename rootViewController to leftViewController as the latter
    // is less likely to conflict with something apple names internally
    UIViewController *_rootViewController;
    UINavigationController *_detailNavigationController;
    UIViewController *_rightViewController;
}

- (void)displayFirstModule;

@property(nonatomic, retain) UIViewController *rootViewController;
@property(nonatomic, retain) UIViewController *rightViewController;
@property(nonatomic) BOOL isShowingModuleHome;

@end
