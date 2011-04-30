#import "KGOSplitViewController.h"
#import "KGOTheme.h"
#import "KGOModule.h"
#import "KGOAppDelegate.h"
#import "HomeModule.h"

@implementation KGOSplitViewController

@synthesize isShowingModuleHome;

/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

- (void)dealloc
{
    self.rootViewController = nil;
    self.rightViewController = nil;
    [_moduleListButton release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [[KGOTheme sharedTheme] backgroundColorForApplication];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

#pragma mark - Properties

- (UIViewController *)rootViewController
{
    return _rootViewController;
}

- (void)setRootViewController:(UIViewController *)rootViewController
{
    [_rootViewController release];
    _rootViewController = [rootViewController retain];
}

- (UIViewController *)rightViewController
{
    return _rightViewController;
}

- (void)setRightViewController:(UIViewController *)viewController
{
    [_rightViewController release];
    _rightViewController = [viewController retain];
    
    if (_moduleListButton) {
        _rightViewController.navigationItem.leftBarButtonItem = _moduleListButton;
    }

    UINavigationController *navC = [[[UINavigationController alloc] initWithRootViewController:viewController] autorelease];
    
    if (_rootViewController && _rightViewController) {
        self.viewControllers = [NSArray arrayWithObjects:_rootViewController, navC, nil];
    }
}

#pragma mark -

- (void)displayFirstModule
{
    KGOModule *firstModule = nil;
    for (KGOModule *aModule in [KGO_SHARED_APP_DELEGATE() modules]) {
        if (!aModule.hidden && aModule.hasAccess) {
            firstModule = aModule;
            break;
        }
    }
    
    if (!firstModule) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(displayFirstModule)
                                                     name:ModuleListDidChangeNotification
                                                   object:nil];

    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        UIViewController *firstModuleVC = [firstModule modulePage:LocalPathPageNameHome params:nil];
        self.rightViewController = firstModuleVC;
        self.isShowingModuleHome = YES;
    }
}

#pragma mark UISplitViewControllerDelegate

- (void)splitViewController:(UISplitViewController *)svc
          popoverController:(UIPopoverController *)pc
  willPresentViewController:(UIViewController *)aViewController
{
    DLog(@"splitVC will present VC %@ %@", aViewController, aViewController.view);
}

- (void)splitViewController:(UISplitViewController *)svc
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)pc
{
    if (self.isShowingModuleHome) {
        _moduleListButton = barButtonItem;
        barButtonItem.title = @"Modules";
        self.rightViewController.navigationItem.leftBarButtonItem = barButtonItem;
        pc.contentViewController = self.rootViewController;
    }

    DLog(@"splitVC will hide VC %@ %@ %@ %@", aViewController, aViewController.view, barButtonItem, pc);
}

- (void)splitViewController:(UISplitViewController *)svc
     willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    _moduleListButton = nil;
    self.rightViewController.navigationItem.leftBarButtonItem = nil;
    
    DLog(@"splitVC will show VC %@ %@ %@", aViewController, aViewController.view, barButtonItem);
}

#pragma mark UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
}

@end
