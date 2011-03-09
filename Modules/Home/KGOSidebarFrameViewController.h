#import "KGOHomeScreenViewController.h"

@interface KGOSidebarFrameViewController : KGOHomeScreenViewController {
    
    UIView *_sidebar;
    UIView *_topbar;
    UIView *_container;
    
    UIViewController *_visibleViewController;
    
}

@property (nonatomic, readonly) UIViewController *visibleViewController;

- (void)showViewController:(UIViewController *)viewController;

@end
