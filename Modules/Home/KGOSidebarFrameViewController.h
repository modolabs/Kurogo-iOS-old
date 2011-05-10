/* because we have home screens like this,
 * ipad view controllers that wish to implement rotation methods
 * should use the app delegate's homescreen method and get its orientation
 * instead of using self.interfaceOrientation 
 */
#import "KGOHomeScreenViewController.h"

@class KGOModule, SpringboardIcon;

@interface KGOSidebarFrameViewController : KGOHomeScreenViewController {
    
    UIView *_sidebar;
    UIImageView *_topbar;
    UIView *_container;
    
    UIViewController *_visibleViewController;
    NSArray *_widgetViews;
    
    UIViewController *_detailViewController;
    UIViewController *_outgoingDetailViewController;
    
    CGFloat _topFreePixel;
    CGFloat _bottomFreePixel;
}

@property (nonatomic, readonly) UIViewController *visibleViewController;
@property (nonatomic, readonly) NSArray *widgetViews;
@property (nonatomic) NSTimeInterval animationDuration;
@property (nonatomic, readonly) UIView *container;
@property (nonatomic, readonly) UIViewController *detailViewController;

- (void)showViewController:(UIViewController *)viewController;
- (void)showDetailViewController:(UIViewController *)viewController;
- (void)hideDetailViewController;

- (void)highlightIconForModule:(KGOModule *)module;
- (void)highlightIcon:(SpringboardIcon *)anIcon;

@end
