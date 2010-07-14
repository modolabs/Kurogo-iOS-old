#import "ModoNavigationController.h"

#define NAV_BAR_HEIGHT 44.0f

@implementation ModoNavigationController

@synthesize modoNavBar = _modoNavBar;

- (id)init {
    if (self = [super init]) {
        _modoNavBar = [[ModoNavigationBar alloc] initWithNavigationBar:self.navigationBar];
        _modoNavBar.delegate = self;
    }
    return self;
}

- (void)updateNavBar {
    [self.modoNavBar update];
}

- (void)loadView {
    [super loadView];
    [self.navigationBar removeFromSuperview];
    [self.view addSubview:_modoNavBar];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [super pushViewController:viewController animated:animated];
    [self updateNavBar];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    UIViewController *vc = [super popViewControllerAnimated:animated];
    [self updateNavBar];
    return vc;
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated {
    NSArray *vcArray = [super popToRootViewControllerAnimated:animated];
    [self updateNavBar];
    return vcArray;
}

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    NSArray *vcArray = [super popToViewController:viewController animated:animated];
    [self updateNavBar];
    return vcArray;
}

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated {
    [super setViewControllers:viewControllers animated:animated];
    [self updateNavBar];
}

/*
- (void)dealloc {
    [super dealloc];
}
*/

@end
