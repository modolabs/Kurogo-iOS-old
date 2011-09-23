#import "KGOHomeScreenViewController.h"
#import "HomeModule.h"
#import "LoginModule.h"
#import "SettingsModule.h"
#import "ExternalURLModule.h"
#import "UIKit+KGOAdditions.h"
#import "SpringboardIcon.h"
#import "KGOHomeScreenWidget.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGORequestManager.h"
#import "Foundation+KGOAdditions.h"
#import "KGOUserSettingsManager.h"

#define MAX_FEDERATED_SEARCH_RESULTS_PER_SECTION 2

@interface KGOHomeScreenViewController (Private)

- (void)loadModules;
- (void)moduleListDidChange:(NSNotification *)aNotification;
+ (GridSpacing)spacingWithArgs:(NSArray *)args;
+ (GridPadding)paddingWithArgs:(NSArray *)args;
+ (CGSize)sizeWithArgs:(NSArray *)args;
+ (CGSize)maxLabelDimensionsForModules:(NSArray *)modules font:(UIFont *)font;

@end


@implementation KGOHomeScreenViewController

@synthesize primaryModules = _primaryModules, secondaryModules = _secondaryModules, homeModule, loadingView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _preferences = [[[KGOTheme sharedTheme] homescreenConfig] retain];
        [self subscribeToModuleChangeNotifications];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        _preferences = [[[KGOTheme sharedTheme] homescreenConfig] retain];
        [self subscribeToModuleChangeNotifications];
    }
    return self;
}

- (void)subscribeToModuleChangeNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moduleListDidChange:)
                                                 name:ModuleListDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moduleListDidChange:)
                                                 name:KGOUserPreferencesDidChangeNotification
                                               object:nil];
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
    [super loadView];
    
    [self loadModules];
    
    if ([self showsSearchBar] && !_searchBar) {
        _searchBar = [[KGOSearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
        _searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
        _searchBar.placeholder = [NSString stringWithFormat:@"%@ %@",
                                  NSLocalizedString(@"Search", nil),
                                  [infoDict objectForKey:@"CFBundleName"]];
        [self.view addSubview:_searchBar];
    }
}

- (void)viewDidLoad {
    UIColor *backgroundColor = [self backgroundColor];
    if (backgroundColor) {
        self.view.backgroundColor = backgroundColor;
    }
    
    // left nav bar button
	UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStyleBordered target:nil action:nil];	
	[[self navigationItem] setBackBarButtonItem: newBackButton];
	[newBackButton release];
    
    // nav bar title
    UIImage *masthead = [[KGOTheme sharedTheme] titleImageForNavBar];
    if (masthead) {
        self.navigationItem.titleView = [[[UIImageView alloc] initWithImage:masthead] autorelease];
    } else {
        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
        self.navigationItem.title = [infoDict objectForKey:@"CFBundleName"];
    }
    
    if (_searchBar && !_searchController) {
        _searchController = [[KGOSearchDisplayController alloc] initWithSearchBar:_searchBar delegate:self contentsController:self];
        _searchController.maxResultsPerSection = MAX_FEDERATED_SEARCH_RESULTS_PER_SECTION;
    }
    
    [self standbyForServerHello];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    [_searchBar release];
    _searchBar = nil;
    
    [_searchController release];
    _searchController = nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_preferences release];
    [_searchBar release];
    [_searchController release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    }
    return toInterfaceOrientation == UIInterfaceOrientationPortrait;
}

#pragma mark - Login states

- (void)standbyForServerHello
{
    // TODO: make KGORequestManager cache states better so we can check
    // whether this is needed.
    [[KGORequestManager sharedManager] requestServerHello];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(helloRequestDidComplete:)
                                                 name:HelloRequestDidCompleteNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(helloRequestDidFail:)
                                                 name:HelloRequestDidFailNotification
                                               object:nil];
    
    [self showLoadingView];
}

- (void)loginDidComplete:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:KGODidLoginNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(logoutDidComplete:)
                                                 name:KGODidLogoutNotification
                                               object:nil];
    
    if (self.homeModule.hasAccess) {
        [self hideLoadingView];
        
    } else {
        [self standbyForServerHello];
    }
}

- (void)logoutDidComplete:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:KGODidLogoutNotification object:nil];
    [self standbyForServerHello];
}

// in response to HelloRequestDidCompleteNotification
- (void)helloRequestDidComplete:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HelloRequestDidFailNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HelloRequestDidCompleteNotification object:nil];
    
    for (KGOModule *aModule in [KGO_SHARED_APP_DELEGATE() modules]) {
        if (!aModule.hasAccess && ![[KGORequestManager sharedManager] isUserLoggedIn]) {
            DLog(@"%@ module requires login: %@", aModule.tag, aModule);
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(loginDidComplete:)
                                                         name:KGODidLoginNotification
                                                       object:nil];
            [[KGORequestManager sharedManager] loginKurogoServer];
            break;
        } else {
            [self hideLoadingView];
        }
    }
}

// in response to HelloRequestDidFailNotification
- (void)helloRequestDidFail:(NSNotification *)aNotification {
    NSString *message = NSLocalizedString(@"Could not connect to server.  Please try again later.",
                                          @"error message for hello request failure");
    NSString *retry = NSLocalizedString(@"Retry", @"retry button for hello request failure");
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:nil
                                                         message:message
                                                        delegate:self 
                                               cancelButtonTitle:NSLocalizedString(@"Cancel", @"cancel button for hello request failure")
                                               otherButtonTitles:retry, nil] autorelease];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        [self loadModules];
        [self refreshModules];
        [self hideLoadingView];

    } else {
        [[KGORequestManager sharedManager] requestServerHello];
    }
}

- (void)showLoadingView
{
    if (!self.loadingView) {
        self.loadingView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)] autorelease];
        self.loadingView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1];
        self.loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        UIViewAutoresizing allMargins =  UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        UIActivityIndicatorView *spinny = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
        [spinny startAnimating];
        spinny.autoresizingMask = allMargins;
        
        NSString *loadingText = NSLocalizedString(@"Loading...", nil);
        UIFont *font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyBodyText];
        CGSize size = [loadingText sizeWithFont:font];
        UILabel *loadingLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)] autorelease];
        loadingLabel.text = loadingText;
        loadingLabel.font = font;
        loadingLabel.textColor = [UIColor whiteColor];
        loadingLabel.autoresizingMask = allMargins;
        loadingLabel.backgroundColor = [UIColor clearColor];
        
        CGFloat combinedWidth = spinny.frame.size.width + loadingLabel.frame.size.width + 5;
        CGFloat combinedX = floor((self.loadingView.frame.size.width - combinedWidth) / 2);
        CGFloat spinnyY = floor((self.loadingView.frame.size.height - spinny.frame.size.height) / 2);
        CGFloat loadingY = floor((self.loadingView.frame.size.height - loadingLabel.frame.size.height) / 2);
        
        loadingLabel.frame = CGRectMake(combinedX + spinny.frame.size.width + 5,
                                        loadingY, loadingLabel.frame.size.width, loadingLabel.frame.size.height);
        spinny.frame = CGRectMake(combinedX, spinnyY, spinny.frame.size.width, spinny.frame.size.height);
        
        [self.loadingView addSubview:loadingLabel];
        [self.loadingView addSubview:spinny];
        [self.view addSubview:self.loadingView];
    }
}

- (void)hideLoadingView
{
    if (self.loadingView) {
        [UIView animateWithDuration:0.2 animations:^(void) {
            self.loadingView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.loadingView removeFromSuperview];
            self.loadingView = nil;
            [self refreshWidgets];
        }];
    }
}

#pragma mark Springboard helper methods

- (CGRect)springboardFrame {
    return self.view.bounds;
}

- (NSArray *)allWidgets:(CGFloat *)topFreePixel :(CGFloat *)bottomFreePixel {
    CGFloat yOrigin = 0;
    if (_searchBar) {
        yOrigin = _searchBar.frame.size.height;
    }
    
    CGSize *occupiedAreas = malloc(sizeof(CGSize) * 4);
    
    occupiedAreas[KGOLayoutGravityTopLeft] = CGSizeZero;
    occupiedAreas[KGOLayoutGravityTopRight] = CGSizeZero;
    occupiedAreas[KGOLayoutGravityBottomLeft] = CGSizeZero;
    occupiedAreas[KGOLayoutGravityBottomRight] = CGSizeZero;
    
    KGOLayoutGravity neighborGravity;
    BOOL downward; // true if new views are laid out from the top
    
    // populate widgets at the top
    //NSMutableArray *overlappingViews = [NSMutableArray array];
    
    NSMutableArray *allWidgets = [NSMutableArray array];
    NSArray *allModules = [self.primaryModules arrayByAddingObjectsFromArray:self.secondaryModules];
    
    for (KGOModule *aModule in allModules) {
        NSArray *moreViews = [aModule widgetViews];
        if (moreViews) {
            DLog(@"preparing widgets for module %@", aModule.tag);
            for (KGOHomeScreenWidget *aWidget in moreViews) {
                aWidget.module = aModule;
                
                if (!aWidget.overlaps) {
                    switch (aWidget.gravity) {
                        case KGOLayoutGravityBottomLeft:
                            neighborGravity = KGOLayoutGravityBottomRight;
                            downward = NO;
                            break;
                        case KGOLayoutGravityBottomRight:
                            neighborGravity = KGOLayoutGravityBottomLeft;
                            downward = NO;
                            break;
                        case KGOLayoutGravityTopRight:
                            neighborGravity = KGOLayoutGravityTopLeft;
                            downward = YES;
                            break;
                        case KGOLayoutGravityTopLeft:
                        default:
                            neighborGravity = KGOLayoutGravityTopRight;
                            downward = YES;
                            break;
                    }
                    
                    CGRect frame = aWidget.frame;
                    
                    CGFloat currentYForGravity;
                    if (frame.size.width + occupiedAreas[neighborGravity].width <= self.springboardFrame.size.width) {
                        currentYForGravity = occupiedAreas[aWidget.gravity].height;
                    } else {
                        currentYForGravity = fmax(occupiedAreas[aWidget.gravity].height, occupiedAreas[neighborGravity].height);
                    }
                    
                    if (downward) {
                        frame.origin.y = yOrigin + currentYForGravity;
                        occupiedAreas[aWidget.gravity].height = frame.origin.y - yOrigin + frame.size.height;
                    } else {
                        frame.origin.y = self.springboardFrame.size.height - currentYForGravity - aWidget.frame.size.height;
                        occupiedAreas[aWidget.gravity].height = self.springboardFrame.size.height - frame.origin.y;
                    }
                    
                    if (frame.size.width > occupiedAreas[aWidget.gravity].width)
                        occupiedAreas[aWidget.gravity].width = frame.size.width;
                    
                    if (aWidget.gravity == KGOLayoutGravityTopRight || aWidget.gravity == KGOLayoutGravityBottomRight) {
                        frame.origin.x = self.springboardFrame.size.width - aWidget.frame.size.width;
                    }
                    aWidget.frame = frame;
                    aWidget.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

                }                

                [allWidgets addObject:aWidget];
            }
        }
    }
    *topFreePixel = yOrigin + fmax(occupiedAreas[KGOLayoutGravityTopLeft].height,
                                             occupiedAreas[KGOLayoutGravityTopRight].height);
    
    *bottomFreePixel = self.springboardFrame.size.height - fmax(occupiedAreas[KGOLayoutGravityBottomLeft].height,
                                                                occupiedAreas[KGOLayoutGravityBottomRight].height);
    free(occupiedAreas);
    return allWidgets;
}

- (void)refreshWidgets {
    ;
}

- (void)refreshModules {
    if ([self showsSettingsInNavBar]) {
        UIImage *image = [UIImage imageWithPathName:@"common/navbar-settings"];
        UIBarButtonItem *item = [[[UIBarButtonItem alloc] initWithImage:image
                                                                  style:UIBarButtonItemStyleBordered
                                                                 target:self
                                                                 action:@selector(showSettingsModule:)] autorelease];
        item.width = 30;
        self.navigationItem.rightBarButtonItem = item;
    }
}

- (NSArray *)iconsForPrimaryModules:(BOOL)isPrimary {
    BOOL useCompactIcons = [KGO_SHARED_APP_DELEGATE() navigationStyle] != KGONavigationStyleTabletSidebar;
    
    NSMutableArray *icons = [NSMutableArray array];
    NSArray *modules = (isPrimary) ? self.primaryModules : self.secondaryModules;
    
    KGOModule *aModule = [modules lastObject];
    CGSize labelSize = (isPrimary) ? [self moduleLabelMaxDimensions] : [self secondaryModuleLabelMaxDimensions];
    CGRect frame = CGRectZero;

    frame.size = (isPrimary) ? [self moduleIconSize] : [self secondaryModuleIconSize];
    if (!frame.size.width || !frame.size.height) {
        frame.size = [[aModule iconImage] size];
    }
    if (useCompactIcons) {
        frame.size.width = fmax(frame.size.width, labelSize.width);
        frame.size.height += labelSize.height + (isPrimary) ? [self moduleLabelTitleMargin] : [self secondaryModuleLabelTitleMargin];
    } else {
        // TODO: don't hard code numbers
        frame.size.width = 180;
    }
    
    for (aModule in modules) {
        SpringboardIcon *anIcon = [[[SpringboardIcon alloc] initWithFrame:frame] autorelease];
        [icons addObject:anIcon];
        anIcon.compact = useCompactIcons;
        
        anIcon.springboard = self;
        anIcon.module = aModule;
        
        // Add properties for accessibility/automation visibility.
        anIcon.isAccessibilityElement = YES;
        anIcon.accessibilityLabel = aModule.longName;
        
        anIcon.enabled = aModule.enabled;
        
        DLog(@"created home screen icon for %@: %@", aModule.tag, [anIcon description]);
    }
    
    return icons;
}

- (void)buttonPressed:(id)sender {
    SpringboardIcon *anIcon = (SpringboardIcon *)sender;
	[KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameHome forModuleTag:anIcon.moduleTag params:nil];
}

- (void)showSettingsModule:(id)sender
{
    // TODO: add a method to retrieve the first instance of a module by class name
    [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameHome forModuleTag:@"settings" params:nil];
}

#pragma mark KGOSearchDisplayDelegate

- (BOOL)searchControllerShouldShowSuggestions:(KGOSearchDisplayController *)controller {
    return YES;
}

- (NSArray *)searchControllerValidModules:(KGOSearchDisplayController *)controller {
    NSMutableArray *searchableModules = [NSMutableArray arrayWithCapacity:5];
    NSArray *modules = [KGO_SHARED_APP_DELEGATE() modules];
    for (KGOModule *aModule in modules) {
        if (aModule.supportsFederatedSearch) {
            [searchableModules addObject:aModule.tag];
        }
    }
    return searchableModules;
}

- (NSString *)searchControllerModuleTag:(KGOSearchDisplayController *)controller {
    return self.homeModule.tag;
}

- (void)resultsHolder:(id<KGOSearchResultsHolder>)searcher didSelectResult:(id<KGOSearchResult>)aResult {
    // FIXME: come up with a better way to figure out which module the search result belongs to
    BOOL didShow = NO;
    if ([aResult respondsToSelector:@selector(didGetSelected:)]) {
        didShow = [aResult didGetSelected:self];
    }

    if (!didShow) {
        NSLog(@"home screen search controller failed to respond to search result %@", [aResult description]);
    }
}

#pragma mark config settings

- (CGSize)moduleLabelMaxDimensions {
    return [KGOHomeScreenViewController maxLabelDimensionsForModules:self.primaryModules font:[self moduleLabelFont]];
}

- (CGSize)secondaryModuleLabelMaxDimensions {
    return [KGOHomeScreenViewController maxLabelDimensionsForModules:self.secondaryModules font:[self secondaryModuleLabelFont]];
}

- (BOOL)showsSearchBar
{
    return [_preferences boolForKey:@"ShowsSearchBar"];
}

- (BOOL)showsSettingsInNavBar
{
    return [_preferences boolForKey:@"ShowsSettingsInNavBar"];
}

- (UIColor *)backgroundColor {
    NSString *colorName = [_preferences objectForKey:@"BackgroundColor"];
    UIColor *color = [UIColor colorWithHexString:colorName];
    if (!color) {
        UIImage *image = [UIImage imageWithPathName:colorName];
        if (image) {
            color = [UIColor colorWithPatternImage:image];
        }
    }
    return color;
}

// primary modules

- (UIFont *)moduleLabelFont {
    NSDictionary *fontArgs = [_preferences objectForKey:@"ModuleLabelFont"];
    NSString *fontName = [fontArgs objectForKey:@"font"];
    if (!fontName) {
        fontName = [[KGOTheme sharedTheme] defaultFontName];
    }
    CGFloat fontOffset = [fontArgs floatForKey:@"size"];
    CGFloat fontSize = [[KGOTheme sharedTheme] defaultFontSize] + fontOffset;
    
    return [UIFont fontWithName:fontName size:fontSize];
}

- (UIFont *)moduleLabelFontLarge {
    NSDictionary *fontArgs = [_preferences objectForKey:@"ModuleLabelFontLarge"];
    NSString *fontName = [fontArgs objectForKey:@"font"];
    if (!fontName) {
        fontName = [[KGOTheme sharedTheme] defaultFontName];
    }
    CGFloat fontOffset = [fontArgs floatForKey:@"size"];
    CGFloat fontSize = [[KGOTheme sharedTheme] defaultFontSize] + fontOffset;
    
    return [UIFont fontWithName:fontName size:fontSize];
}

- (UIColor *)moduleLabelTextColor {
    NSDictionary *fontArgs = [_preferences objectForKey:@"ModuleLabelFont"];
    UIColor *color = [UIColor colorWithHexString:[fontArgs objectForKey:@"color"]];
    if (!color)
        color = [UIColor blackColor];
    return color;
}

- (GridSpacing)moduleListSpacing {
    NSArray *args = [[_preferences objectForKey:@"ModuleListSpacing"] componentsSeparatedByString:@" "];
    return [KGOHomeScreenViewController spacingWithArgs:args];
}

- (GridPadding)moduleListMargins {
    NSArray *args = [[_preferences objectForKey:@"ModuleListMargins"] componentsSeparatedByString:@" "];
    return [KGOHomeScreenViewController paddingWithArgs:args];
}

- (CGFloat)moduleLabelTitleMargin {
    NSNumber *number = [_preferences objectForKey:@"ModuleLabelTitleMargin"];
    return [number floatValue];
}

- (CGSize)moduleIconSize {
    NSArray *args = [[_preferences objectForKey:@"ModuleIconSize"] componentsSeparatedByString:@" "];
    return [KGOHomeScreenViewController sizeWithArgs:args];
}

// secondary modules

- (UIFont *)secondaryModuleLabelFont {
    NSDictionary *fontArgs = [_preferences objectForKey:@"SecondaryModuleLabelFont"];
    NSString *fontName = [fontArgs objectForKey:@"font"];
    if (!fontName) {
        fontName = [[KGOTheme sharedTheme] defaultFontName];
    }
    CGFloat fontOffset = [fontArgs floatForKey:@"size"];
    CGFloat fontSize = [[KGOTheme sharedTheme] defaultFontSize] + fontOffset;
    
    return [UIFont fontWithName:fontName size:fontSize];
}

- (UIColor *)secondaryModuleLabelTextColor {
    NSDictionary *fontArgs = [_preferences objectForKey:@"SecondaryModuleLabelFont"];
    UIColor *color = [UIColor colorWithHexString:[fontArgs objectForKey:@"color"]];
    if (!color)
        color = [UIColor blackColor];
    return color;
}

- (GridSpacing)secondaryModuleListSpacing {
    NSArray *args = [[_preferences objectForKey:@"SecondaryModuleListSpacing"] componentsSeparatedByString:@" "];
    return [KGOHomeScreenViewController spacingWithArgs:args];
}

- (GridPadding)secondaryModuleListMargins {
    NSArray *args = [[_preferences objectForKey:@"SecondaryModuleListMargins"] componentsSeparatedByString:@" "];
    return [KGOHomeScreenViewController paddingWithArgs:args];
}

- (CGFloat)secondaryModuleLabelTitleMargin {
    NSNumber *number = [_preferences objectForKey:@"SecondaryModuleLabelTitleMargin"];
    return [number floatValue];
}

- (CGSize)secondaryModuleIconSize {
    NSArray *args = [[_preferences objectForKey:@"SecondaryModuleIconSize"] componentsSeparatedByString:@" "];
    return [KGOHomeScreenViewController sizeWithArgs:args];
}

#pragma mark Private

- (void)moduleListDidChange:(NSNotification *)aNotification
{
    [self loadModules];
    [self refreshWidgets];
    [self refreshModules];
}

- (void)loadModules {
    NSArray *modules = [KGO_SHARED_APP_DELEGATE() modules];
    NSMutableArray *primary = [NSMutableArray array];
    NSMutableArray *secondary = [NSMutableArray array];
    
    BOOL networkIsReachable = [[KGORequestManager sharedManager] isReachable];
    
    for (KGOModule *aModule in modules) {
        // special case for home module
        if ([aModule isKindOfClass:[HomeModule class]]) {
            self.homeModule = aModule;
        }

        if (aModule.hidden || !aModule.hasAccess) {
            DLog(@"skipping module %@", aModule);
            continue;
        }

        // TODO: make the home API report whether modules are secondary
        if ([aModule isKindOfClass:[LoginModule class]]) {
            aModule.secondary = YES;
        }
        
        if (aModule.secondary) {
            [secondary addObject:aModule];
        } else {
            [primary addObject:aModule];
        }
        
        aModule.enabled = networkIsReachable || ![aModule requiresKurogoServer];
    }

    NSDictionary *modulePreference = [[KGOUserSettingsManager sharedManager] selectedValueDictForSetting:@"Modules"];
    __block NSArray *moduleOrder = [modulePreference objectForKey:@"items"];

    NSComparisonResult (^moduleSort)(id, id) = ^(id obj1, id obj2) {
        NSInteger order1 = [moduleOrder indexOfObject:[(KGOModule *)obj1 tag]];
        NSInteger order2 = [moduleOrder indexOfObject:[(KGOModule *)obj2 tag]];
        if (order1 > order2)
            return NSOrderedDescending;
        else
            return (order1 < order2) ? NSOrderedAscending : NSOrderedSame;
    };
    
    [_secondaryModules release];
    _secondaryModules = [[secondary sortedArrayUsingComparator:moduleSort] retain];
    
    [_primaryModules release];
    _primaryModules = [[primary sortedArrayUsingComparator:moduleSort] retain];
}

+ (GridPadding)paddingWithArgs:(NSArray *)args {
    // top, left, bottom, right
    GridPadding padding = GridPaddingZero;
    for (NSInteger i = 0; i < args.count; i++) {
        CGFloat value = [[args objectAtIndex:i] floatValue];
        switch (i) {
            case 0:
                padding.top = value;
                break;
            case 1:
                padding.left = value;
                break;
            case 2:
                padding.bottom = value;
                break;
            case 3:
                padding.right = value;
                break;
        }
    }
    return padding;
}

+ (GridSpacing)spacingWithArgs:(NSArray *)args {
    // width, height
    GridSpacing spacing = GridSpacingZero;
    for (NSInteger i = 0; i < args.count; i++) {
        CGFloat value = [[args objectAtIndex:i] floatValue];
        switch (i) {
            case 0:
                spacing.width = value;
                break;
            case 1:
                spacing.height = value;
                break;
        }
    }
    return spacing;
}

+ (CGSize)sizeWithArgs:(NSArray *)args {
    CGSize size = CGSizeZero;
    for (NSInteger i = 0; i < args.count; i++) {
        CGFloat value = [[args objectAtIndex:i] floatValue];
        switch (i) {
            case 0:
                size.width = value;
                break;
            case 1:
                size.height = value;
                break;
        }
    }
    return size;
}

+ (CGSize)maxLabelDimensionsForModules:(NSArray *)modules font:(UIFont *)font {
    CGFloat maxWidth = 0;
    CGFloat maxHeight = 0;
    for (KGOModule *aModule in modules) {
        NSArray *words = [aModule.longName componentsSeparatedByString:@" "];
        for (NSString *aWord in words) {
            CGSize size = [aWord sizeWithFont:font];
            if (size.width > maxWidth) {
                maxWidth = size.width;
            }
        }
        CGFloat height = [font lineHeight] * [words count];
        if (height > maxHeight) {
            maxHeight = height;
        }
    }
    return CGSizeMake(maxWidth, maxHeight);
}

@end
