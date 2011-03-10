#import "KGOSidebarFrameViewController.h"
#import "SpringboardIcon.h"

@interface KGOSidebarFrameViewController (Private)

- (void)setupSidebarIcons;

@end

@implementation KGOSidebarFrameViewController


- (void)showViewController:(UIViewController *)viewController {
    if (viewController != _visibleViewController) {
        [_visibleViewController.view removeFromSuperview];
        
        [_visibleViewController release];
        _visibleViewController = [viewController retain];

        _visibleViewController.view.frame = CGRectMake(0, 0, _container.frame.size.width, _container.frame.size.height);
        [_container addSubview:viewController.view];
    }
}

- (UIViewController *)visibleViewController {
    return _visibleViewController;
}

#pragma mark -

- (void)dealloc
{
    [_visibleViewController release];
    [_topbar release];
    [_sidebar release];
    [_container release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    [super loadView];
    
    _topbar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50)];
    _topbar.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_topbar];
    
    _sidebar = [[UIView alloc] initWithFrame:CGRectMake(0, _topbar.frame.size.height, 180, self.view.bounds.size.height)];
    [self.view addSubview:_sidebar];
    [self setupSidebarIcons];
    
    _container = [[UIView alloc] initWithFrame:CGRectMake(_sidebar.frame.size.width,
                                                          _topbar.frame.size.height,
                                                          self.view.bounds.size.width - _sidebar.frame.size.width,
                                                          self.view.bounds.size.height - _topbar.frame.size.height)];
    [self.view addSubview:_container];
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

#pragma mark -

- (void)setupSidebarIcons {
    NSArray *primaryIcons = [self iconsForPrimaryModules:YES];
    CGRect frame;
    CGFloat currentY = 0;
    for (SpringboardIcon *anIcon in primaryIcons) {
        frame = anIcon.frame;
        frame.origin.y = currentY;
        anIcon.frame = frame;
        [_sidebar addSubview:anIcon];
        currentY += frame.size.height + 10;
    }
}

@end
