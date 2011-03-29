#import "KGOHomeScreenViewController.h"
#import "HomeModule.h"
#import "LoginModule.h"
#import "SettingsModule.h"
#import "ExternalURLModule.h"
#import "UIKit+KGOAdditions.h"
#import "SpringboardIcon.h"
#import "KGOPersonWrapper.h"
#import "KGOHomeScreenWidget.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGORequestManager.h"

@interface KGOHomeScreenViewController (Private)

- (void)loadModules;
- (void)moduleListDidChange:(NSNotification *)aNotification;
+ (GridSpacing)spacingWithArgs:(NSArray *)args;
+ (GridPadding)paddingWithArgs:(NSArray *)args;
+ (CGSize)maxLabelDimensionsForModules:(NSArray *)modules font:(UIFont *)font;

@end


@implementation KGOHomeScreenViewController

@synthesize primaryModules = _primaryModules, secondaryModules = _secondaryModules, homeModule;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		NSString * file = [[NSBundle mainBundle] pathForResource:@"ThemeConfig" ofType:@"plist"];
        NSDictionary *themeDict = [NSDictionary dictionaryWithContentsOfFile:file];
        _preferences = [[themeDict objectForKey:@"HomeScreen"] retain];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(moduleListDidChange:)
                                                     name:ModuleListDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
		NSString * file = [[NSBundle mainBundle] pathForResource:@"ThemeConfig" ofType:@"plist"];
        NSDictionary *themeDict = [NSDictionary dictionaryWithContentsOfFile:file];
        _preferences = [[themeDict objectForKey:@"HomeScreen"] retain];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(moduleListDidChange:)
                                                     name:ModuleListDidChangeNotification
                                                   object:nil];
    }
    return self;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
    [super loadView];
    
    //_springboardFrame = self.view.bounds;
    
    [self loadModules];
    
    if ([self showsSearchBar]) {
        _searchBar = [[KGOSearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
        _searchBar.placeholder = [NSString stringWithFormat:@"Search %@", [infoDict objectForKey:@"CFBundleName"]];
        [self.view addSubview:_searchBar];
    }
}

- (void)viewDidLoad {
    UIImage *background = [self backgroundImage];
    if (background) {
        self.view.backgroundColor = [UIColor colorWithPatternImage:background];
    }
    
	UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStyleBordered target:nil action:nil];	
	[[self navigationItem] setBackBarButtonItem: newBackButton];
	[newBackButton release];
    
    UIImage *masthead = [[KGOTheme sharedTheme] titleImageForNavBar];
    if (masthead) {
        self.navigationItem.titleView = [[[UIImageView alloc] initWithImage:masthead] autorelease];
    } else {
        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
        self.navigationItem.title = [infoDict objectForKey:@"CFBundleName"];
    }
    
    if (!_searchController) {
        _searchController = [[KGOSearchDisplayController alloc] initWithSearchBar:_searchBar delegate:self contentsController:self];
    }
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [_searchController release];
    _searchController = nil;
}

- (void)dealloc {
    [_preferences release];
    [_searchBar release];
    [_searchController release];
    [super dealloc];
}

- (void)showLoadingView
{
    UIView *container = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)] autorelease];
    container.tag = 3245;
    container.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    container.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UIActivityIndicatorView *spinny = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
    [spinny startAnimating];
    spinny.center = container.center;
    spinny.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    [container addSubview:spinny];
    [self.view addSubview:container];
}

- (void)hideLoadingView
{
    UIView *loadingView = [self.view viewWithTag:3245];
    [loadingView removeFromSuperview];
}

#pragma mark Springboard helper methods

- (CGRect)springboardFrame {
    //return _springboardFrame;
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
    ;
}

- (NSArray *)iconsForPrimaryModules:(BOOL)isPrimary {
    BOOL useCompactIcons = [KGO_SHARED_APP_DELEGATE() navigationStyle] != KGONavigationStyleTabletSidebar;
    
    NSMutableArray *icons = [NSMutableArray array];
    NSArray *modules = (isPrimary) ? self.primaryModules : self.secondaryModules;
    
    KGOModule *aModule = [modules lastObject];
    CGSize labelSize = (isPrimary) ? [self moduleLabelMaxDimensions] : [self secondaryModuleLabelMaxDimensions];
    CGRect frame = CGRectZero;
    
    frame.size = [aModule iconImage].size;
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
        
        DLog(@"created home screen icon for %@: %@", aModule.tag, [anIcon description]);
    }
    
    return icons;
}

- (void)buttonPressed:(id)sender {
    SpringboardIcon *anIcon = (SpringboardIcon *)sender;
	[KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameHome forModuleTag:anIcon.moduleTag params:nil];
}

#pragma mark KGOSearchDisplayDelegate

- (BOOL)searchControllerShouldShowSuggestions:(KGOSearchDisplayController *)controller {
    return YES;
}

- (NSArray *)searchControllerValidModules:(KGOSearchDisplayController *)controller {
    NSMutableArray *searchableModules = [NSMutableArray arrayWithCapacity:4];
    NSArray *modules = [KGO_SHARED_APP_DELEGATE() modules];
    for (KGOModule *aModule in modules) {
        if (aModule.supportsFederatedSearch) {
            [searchableModules addObject:aModule.tag];
        }
    }
    return searchableModules;
}

- (NSString *)searchControllerModuleTag:(KGOSearchDisplayController *)controller {
    return HomeTag;
}

- (void)searchController:(KGOSearchDisplayController *)controller didSelectResult:(id<KGOSearchResult>)aResult {
    // TODO: come up with a better way to figure out which module the search result belongs to
    BOOL didShow = NO;
    if ([aResult isKindOfClass:[KGOPersonWrapper class]]) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:aResult, @"personDetails", nil];
        didShow = [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail forModuleTag:PeopleTag params:params];
    }
    
    if (!didShow) {
        NSLog(@"home screen search controller failed to respond to search result %@", [aResult description]);
    }
}

#pragma mark config settings

- (CGSize)moduleLabelMaxDimensions {
    return [KGOHomeScreenViewController maxLabelDimensionsForModules:_primaryModules font:[self moduleLabelFont]];
}

- (CGSize)secondaryModuleLabelMaxDimensions {
    return [KGOHomeScreenViewController maxLabelDimensionsForModules:_secondaryModules font:[self secondaryModuleLabelFont]];
}

- (BOOL)showsSearchBar {
    NSNumber *number = [_preferences objectForKey:@"ShowsSearchBar"];
    return [number boolValue];
}

- (UIImage *)backgroundImage {
    NSString *filename = [_preferences objectForKey:@"BackgroundImage"];
    return [UIImage imageWithPathName:filename];
}

// primary modules

- (UIFont *)moduleLabelFont {
    NSDictionary *fontArgs = [_preferences objectForKey:@"ModuleLabelFont"];
    return [UIFont fontWithName:[fontArgs objectForKey:@"font"] size:[[fontArgs objectForKey:@"size"] floatValue]];
}

- (UIFont *)moduleLabelFontLarge {
    NSDictionary *fontArgs = [_preferences objectForKey:@"ModuleLabelFontLarge"];
    return [UIFont fontWithName:[fontArgs objectForKey:@"font"] size:[[fontArgs objectForKey:@"size"] floatValue]];
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

// secondary modules

- (UIFont *)secondaryModuleLabelFont {
    NSDictionary *fontArgs = [_preferences objectForKey:@"SecondaryModuleLabelFont"];
    return [UIFont fontWithName:[fontArgs objectForKey:@"font"] size:[[fontArgs objectForKey:@"size"] floatValue]];
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
    
    for (KGOModule *aModule in modules) {
        // special case for home module
        if ([aModule isKindOfClass:[HomeModule class]]) {
            self.homeModule = aModule;
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
    }

    [_secondaryModules release];
    _secondaryModules = [secondary copy];
    
    [_primaryModules release];
    _primaryModules = [primary copy];
    
    if (self.homeModule.secure && ![[KGORequestManager sharedManager] isUserLoggedIn]) {
        [[KGORequestManager sharedManager] loginKurogoServer];
    }
}

+ (GridPadding)paddingWithArgs:(NSArray *)args {
    // top, left, bottom, right
    GridPadding padding;
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
    GridSpacing spacing;
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
