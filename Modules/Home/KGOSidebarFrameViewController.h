#import "KGOHomeScreenViewController.h"

@class KGOModule;

@interface KGOSidebarFrameViewController : KGOHomeScreenViewController {
    
    UIView *_sidebar;
    UIView *_topbar;
    UIView *_container;
    
    UIViewController *_visibleViewController;
    NSArray *_widgetViews;
    
}

@property (nonatomic, readonly) UIViewController *visibleViewController;

- (void)showViewController:(UIViewController *)viewController;

@end
