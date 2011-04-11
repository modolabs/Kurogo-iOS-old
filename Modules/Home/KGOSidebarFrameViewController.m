#import "KGOSidebarFrameViewController.h"
#import "SpringboardIcon.h"
#import "KGOModule.h"
#import "UIKit+KGOAdditions.h"
#import "KGOHomeScreenWidget.h"
#import <QuartzCore/QuartzCore.h>

#define SIDEBAR_WIDTH 160
#define TOPBAR_HEIGHT 50

#define DETAIL_VIEW_WIDTH 320
#define DETAIL_VIEW_HEIGHT 460

@interface KGOSidebarFrameViewController (Private)

- (void)setupSidebarIcons;

@end

@implementation KGOSidebarFrameViewController


- (void)showViewController:(UIViewController *)viewController {
    if (viewController != _visibleViewController) {
        [_visibleViewController.view removeFromSuperview];
        
        [_visibleViewController release];
        _visibleViewController = [viewController retain];
        [self hideDetailViewController];

        [_visibleViewController viewWillAppear:NO];
        _visibleViewController.view.frame = CGRectMake(0, 0, _container.frame.size.width, _container.frame.size.height);
        [_container addSubview:viewController.view];
    }
}

- (void)showDetailViewController:(UIViewController *)viewController
{
    _detailViewController = [viewController retain];
    _detailViewController.view.frame = CGRectMake(_container.frame.size.width - DETAIL_VIEW_WIDTH - 10,
                                                  _container.frame.size.height - DETAIL_VIEW_HEIGHT - 10,
                                                  DETAIL_VIEW_WIDTH,
                                                  DETAIL_VIEW_HEIGHT);
    _detailViewController.view.layer.cornerRadius = 5;
    [_container addSubview:_detailViewController.view];
}

- (void)hideDetailViewController
{
    [_detailViewController.view removeFromSuperview];
    [_detailViewController release];
    _detailViewController = nil;
}

- (UIViewController *)visibleViewController {
    return _visibleViewController;
}

#pragma mark -

- (void)dealloc
{
    [_visibleViewController release];
    [_detailViewController release];
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
    
    _topbar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, TOPBAR_HEIGHT)];
    _topbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _topbar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithPathName:@"modules/home/ipad-topbar.png"]];
    [self.view addSubview:_topbar];
    
    _sidebar = [[UIView alloc] initWithFrame:CGRectMake(0, TOPBAR_HEIGHT, SIDEBAR_WIDTH, self.view.bounds.size.height - TOPBAR_HEIGHT)];
    _sidebar.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    //_springboardFrame = _sidebar.frame;
    
    [self.view addSubview:_sidebar];
    [self refreshModules];
    [self refreshWidgets];
    
    _container = [[UIView alloc] initWithFrame:CGRectMake(_sidebar.frame.size.width,
                                                          _topbar.frame.size.height,
                                                          self.view.bounds.size.width - _sidebar.frame.size.width,
                                                          self.view.bounds.size.height - _topbar.frame.size.height)];
    _container.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_container];
    
    if (self.primaryModules.count) {
        KGOModule *defaultModule = [self.primaryModules objectAtIndex:0];
        [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameHome
                               forModuleTag:defaultModule.tag
                                     params:nil];
    }
}

- (CGRect)springboardFrame
{
    return _sidebar.frame;
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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [_visibleViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    NSLog(@"%@", self.view);
    [self refreshWidgets];
    
    [_visibleViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

#pragma mark -

- (void)refreshWidgets {
    CGFloat topFreePixel;
    CGFloat bottomFreePixel;
    NSArray *widgets = [self allWidgets:&topFreePixel :&bottomFreePixel];
    
    for (KGOHomeScreenWidget *aWidget in _widgetViews) {
        [aWidget removeFromSuperview];
    }
    
    NSMutableArray *mutableWidgetViews = [NSMutableArray array];
    for (KGOHomeScreenWidget *aWidget in widgets) {
        [mutableWidgetViews addObject:aWidget];
        [_sidebar addSubview:aWidget];
    }
    [_widgetViews release];
    _widgetViews = [mutableWidgetViews copy];
}

- (void)refreshModules {
    [super refreshModules];

    // TODO: move this section out of setupSidebarIcons
    UIImageView *imageView = (UIImageView *)[_sidebar viewWithTag:1234];
    if (!imageView) {
        imageView = [[[UIImageView alloc] initWithImage:[UIImage imageWithPathName:@"modules/home/ipad-sidebar-header"]] autorelease];
        imageView.tag = 1234;
        [_sidebar addSubview:imageView];
    }
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
}

@end
