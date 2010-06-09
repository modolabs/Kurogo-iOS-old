
#import <Foundation/Foundation.h>


@interface MITSearchEffects : UIControl {
	
	UIViewController *theController;

}

- (void)removeBuiltInOverlay;

+ (MITSearchEffects *) overlayForTableviewController: (UITableViewController *)controller;

+ (CGRect) frameWithHeader: (UIView *)headerView;

@property (nonatomic, assign) UIViewController *controller; 

@end
