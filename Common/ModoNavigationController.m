#import "ModoNavigationController.h"
#import "MIT_MobileAppDelegate.h"
#import "MITModule.h"

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

    // save module's view controllers
    if ([self.viewControllers count] > 1) {
        MIT_MobileAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        for (MITModule *aModule in appDelegate.modules) {
            if ([aModule rootViewController] == [self.viewControllers objectAtIndex:1]) {
                aModule.viewControllers = [self.viewControllers subarrayWithRange:NSMakeRange(1, [self.viewControllers count] - 1)];
                break;
            }
        }
    }
}


- (void)loadView {
    [super loadView];
    [self.navigationBar addSubview:_modoNavBar];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [super pushViewController:viewController animated:animated];
    [self setViewControllers:self.viewControllers animated:NO];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    // this seemingly innocuous step somehow forces the navcontroller
    // to show the nav item of the visible viewcontroller.
    [self setViewControllers:self.viewControllers animated:NO];
    UIViewController *vc = [super popViewControllerAnimated:animated];
    [self updateNavBar];
    return vc;
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated {
    [self setViewControllers:self.viewControllers animated:NO];
    NSArray *vcArray = [super popToRootViewControllerAnimated:animated];
    [self updateNavBar];
    return vcArray;
}

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self setViewControllers:self.viewControllers animated:NO];
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
