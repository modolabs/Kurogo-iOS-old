#import "KGOSidebarFrameViewController.h"
#import "SpringboardIcon.h"
#import "KGOModule.h"
#import "UIKit+KGOAdditions.h"
#import "KGOHomeScreenWidget.h"
#import <QuartzCore/QuartzCore.h>

#define SIDEBAR_WIDTH 160
#define TOPBAR_HEIGHT 51

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
    
    _topbar = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, TOPBAR_HEIGHT)];
    _topbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _topbar.image = [UIImage imageWithPathName:@"common/navbar-background"];
    _topbar.userInteractionEnabled = YES;
    [self.view addSubview:_topbar];
    
    // fake toolbar
    UIImage *image = [UIImage imageWithPathName:@"common/scrolltabs-background-opaque"];
    UIImageView *fakeToolbar = [[[UIImageView alloc] initWithFrame:CGRectMake(0, TOPBAR_HEIGHT, self.view.bounds.size.width, image.size.height)] autorelease];
    fakeToolbar.image = image;
    fakeToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:fakeToolbar];
    
    _sidebar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SIDEBAR_WIDTH, self.view.bounds.size.height)];
    _sidebar.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    [self.view addSubview:_sidebar];
    [self refreshModules];
    [self refreshWidgets];

    CGRect containerFrame = CGRectMake(_sidebar.frame.size.width, _topbar.frame.size.height, 0,
                                       self.view.bounds.size.height - _topbar.frame.size.height);
    
    if (UIInterfaceOrientationIsLandscape([self interfaceOrientation])) {
        containerFrame.size.width = self.view.bounds.size.width - SIDEBAR_WIDTH * 2;
        
    } else {
        containerFrame.size.width = self.view.bounds.size.width - SIDEBAR_WIDTH;
    }
    
    _container = [[UIView alloc] initWithFrame:containerFrame];

    [self.view addSubview:_container];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // TODO: make sure this doesn't load multiple buttons
    if ([self showsSettingsInNavBar]) {
        UIImage *settingsImage = [UIImage imageWithPathName:@"common/navbar-settings"];
        UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [settingsButton setImage:settingsImage forState:UIControlStateNormal];
        
        UIImage *background = [UIImage imageWithPathName:@"common/generic-button-background"];
        UIImage *pressedBackground = [UIImage imageWithPathName:@"common/generic-button-background-pressed"];
        
        [settingsButton setBackgroundImage:[background stretchableImageWithLeftCapWidth:8 topCapHeight:8]
                                  forState:UIControlStateNormal];
        [settingsButton setBackgroundImage:[pressedBackground stretchableImageWithLeftCapWidth:8 topCapHeight:8]
                                  forState:UIControlStateHighlighted];

        CGFloat buttonWidth = settingsImage.size.width + 10;
        CGFloat buttonHeight = settingsImage.size.height + 10;
        settingsButton.frame = CGRectMake(_topbar.frame.size.width - buttonWidth - 10,
                                          floor((_topbar.frame.size.height - buttonHeight) / 2),
                                          buttonWidth, buttonHeight);
        
        [settingsButton addTarget:self action:@selector(showSettingsModule:) forControlEvents:UIControlEventTouchUpInside];
        settingsButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [_topbar addSubview:settingsButton];
    }
    
    // TODO: doing this here doesn't have any effect since we don't know the module list
    if (self.primaryModules.count) {
        KGOModule *defaultModule = [self.primaryModules objectAtIndex:0];
        [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameHome
                               forModuleTag:defaultModule.tag
                                     params:nil];
    }
}

- (CGRect)springboardFrame
{
    return self.view.frame;
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
    CGRect frame = _container.frame;
    
    CGFloat currentWidth = self.view.bounds.size.width;
    CGFloat currentHeight = self.view.bounds.size.height;
    
    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
    UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    // TODO: figure out what's really supposed to happen here
    if (UIInterfaceOrientationIsPortrait(statusBarOrientation)) {

    } else if (UIInterfaceOrientationIsLandscape(statusBarOrientation)) {
        currentWidth -= statusBarFrame.size.width;
        currentHeight += statusBarFrame.size.width;
    }
    
    CGFloat longerDimension = fmaxf(currentWidth, currentHeight);
    CGFloat shorterDimension = fminf(currentWidth, currentHeight);
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        frame.size.width = shorterDimension - SIDEBAR_WIDTH;
        frame.size.height = longerDimension - _topbar.frame.size.height;

    } else if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        frame.size.width = longerDimension - SIDEBAR_WIDTH * 2;
        frame.size.height = shorterDimension - _topbar.frame.size.height;
        
    } else {
        return;
    }

    __block KGOSidebarFrameViewController *blockSelf = self;
    [UIView animateWithDuration:duration animations:^(void) {
        _container.frame = frame;
        _visibleViewController.view.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    } completion:^(BOOL finished) {
        [blockSelf refreshWidgets];
    }];
    
    [_visibleViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{    
    [self refreshWidgets];
    
    [_visibleViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

#pragma mark -

- (NSArray *)widgetViews
{
    return _widgetViews;
}

- (void)refreshWidgets {
    NSArray *widgets = [self allWidgets:&_topFreePixel :&_bottomFreePixel];
    
    for (KGOHomeScreenWidget *aWidget in _widgetViews) {
        [aWidget removeFromSuperview];
    }
    
    NSMutableArray *mutableWidgetViews = [NSMutableArray array];
    for (KGOHomeScreenWidget *aWidget in widgets) {
        [mutableWidgetViews addObject:aWidget];
        [self.view addSubview:aWidget];
    }
    [_widgetViews release];
    _widgetViews = [mutableWidgetViews copy];
}

- (void)refreshModules {
    [super refreshModules];
    
    for (UIView *aView in _sidebar.subviews) {
        [aView removeFromSuperview];
    }

    NSArray *primaryIcons = [self iconsForPrimaryModules:YES];
    CGRect frame;
    CGFloat currentY = _topFreePixel;
    for (SpringboardIcon *anIcon in primaryIcons) {
        frame = anIcon.frame;
        frame.origin.y = currentY;
        anIcon.frame = frame;
        [_sidebar addSubview:anIcon];
        currentY += frame.size.height + 10;
    }
}

@end
