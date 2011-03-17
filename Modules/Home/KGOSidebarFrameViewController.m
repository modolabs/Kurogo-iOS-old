#import "KGOSidebarFrameViewController.h"
#import "SpringboardIcon.h"
#import "KGOModule.h"
#import "UIKit+KGOAdditions.h"
#import "KGOHomeScreenWidget.h"

#define SIDEBAR_WIDTH 160

@interface KGOSidebarFrameViewController (Private)

- (void)setupSidebarIcons;
- (void)setupWidgets;

@end

@implementation KGOSidebarFrameViewController


- (void)showViewController:(UIViewController *)viewController {
    if (viewController != _visibleViewController) {
        [_visibleViewController.view removeFromSuperview];
        
        [_visibleViewController release];
        _visibleViewController = [viewController retain];

        [_visibleViewController viewWillAppear:NO];
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
    _topbar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithPathName:@"modules/home/ipad-topbar.png"]];
    [self.view addSubview:_topbar];
    
    _sidebar = [[UIView alloc] initWithFrame:CGRectMake(0, _topbar.frame.size.height, SIDEBAR_WIDTH, self.view.bounds.size.height)];
    _springboardFrame = _sidebar.frame;
    
    [self.view addSubview:_sidebar];
    [self setupSidebarIcons];
    [self setupWidgets];
    
    _container = [[UIView alloc] initWithFrame:CGRectMake(_sidebar.frame.size.width,
                                                          _topbar.frame.size.height,
                                                          self.view.bounds.size.width - _sidebar.frame.size.width,
                                                          self.view.bounds.size.height - _topbar.frame.size.height)];
    [self.view addSubview:_container];
    
    if (self.primaryModules.count) {
        KGOModule *defaultModule = [self.primaryModules objectAtIndex:0];
        [(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] showPage:LocalPathPageNameHome
                                                                    forModuleTag:defaultModule.tag
                                                                          params:nil];
    }
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

- (void)setupWidgets {
    
    NSArray *allModules = [self.primaryModules arrayByAddingObjectsFromArray:self.secondaryModules];
    
    for (KGOModule *aModule in allModules) {
        NSArray *moreViews = [aModule widgetViews];
        // ignoring placement for now
        if (moreViews) {
            for (KGOHomeScreenWidget *aWidget in moreViews) {
                aWidget.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
                [self.view addSubview:aWidget];
                
            }
        }
    }
}

- (void)setupSidebarIcons {
    // TODO: move this section out of setupSidebarIcons
    UIImageView *imageView = [[[UIImageView alloc] initWithImage:[UIImage imageWithPathName:@"modules/home/ipad-sidebar-header"]] autorelease];
    [_sidebar addSubview:imageView];
    /////
    
    NSArray *primaryIcons = [self iconsForPrimaryModules:YES];
    CGRect frame;
    //CGFloat currentY = 0;
    CGFloat currentY = imageView.frame.size.height;
    for (SpringboardIcon *anIcon in primaryIcons) {
        frame = anIcon.frame;
        frame.origin.y = currentY;
        anIcon.frame = frame;
        [_sidebar addSubview:anIcon];
        currentY += frame.size.height + 10;
    }
    
    CGFloat topFreePixel;
    CGFloat bottomFreePixel;
    NSArray *widgets = [self allWidgets:&topFreePixel :&bottomFreePixel];
    
    for (KGOHomeScreenWidget *aWidget in widgets) {
        [self.view addSubview:aWidget];
    }
}

@end
