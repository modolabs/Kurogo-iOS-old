/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import "HarvardNavigationController.h"
#import "KGOAppDelegate.h"
#import "KGOModule.h"

#define NAV_BAR_HEIGHT 44.0f

@implementation HarvardNavigationController

@synthesize modoNavBar = _modoNavBar;

- (id)init {
    self = [super init];
    if (self) {
        _modoNavBar = [[HarvardNavigationBar alloc] initWithNavigationBar:self.navigationBar];
        _modoNavBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _modoNavBar.delegate = self;
    }
    return self;
}

- (void)updateNavBar {

    [self.modoNavBar update];

    // save module's view controllers
    if ([self.viewControllers count] > 1) {
        KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
        for (KGOModule *aModule in appDelegate.modules) {
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
- (void)navigationBar:(UINavigationBar *)navigationBar didPushItem:(UINavigationItem *)item {
}
*/

// called by HarvardNavigationBar prior to popping a navigation item.
// occasionally the back button from the previous item doesn't get hidden as expected
// so we force it to be removed in the navigationBar didPopItem
- (void)navigationBar:(HarvardNavigationBar *)navigationBar willHideSubviews:(NSArray *)subviews {
    oldSubviews = [subviews retain];
}

- (void)navigationBar:(UINavigationBar *)navigationBar didPopItem:(UINavigationItem *)item {
    for (UIView *aView in oldSubviews) {
        [aView removeFromSuperview];
    }
    [oldSubviews release];
    oldSubviews = nil;
}


- (void)dealloc {
    [_modoNavBar release];
    [oldSubviews release];
    [super dealloc];
}


@end
