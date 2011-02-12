/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import "SpringboardViewController.h"
#import "KGOAppDelegate.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "MITUIConstants.h"
#import "KGOModule.h"
#import "ModoNavigationController.h"
#import "ModoNavigationBar.h"
#import "KGOSearchBar.h"
#import "KGOSearchDisplayController.h"
#import "AnalyticsWrapper.h"
#import "UIKit+KGOAdditions.h"

#import "PersonDetails.h"

// extra vertical padding above top row of main icons
#define GRID_TOP_MARGIN 4.0f

// horizontal spacing between main icons
// 0.0 for four icons per row
// 20.0 for three icons per row
#define MAIN_GRID_HPADDING 0.0f

// horizontal spacing between secondary icons
// 20.0 for four icons per row
#define SECONDARY_GRID_HPADDING 20.0f

// vertical spacing between icons
#define GRID_VPADDING 20.0f

// height to allocate to icon text label
#define ICON_LABEL_HEIGHT 23.0f

// internal padding within each icon (allows longer text labels)
#define ICON_PADDING 5.0f

// vertical padding above secondary (utility) icons
#define SECONDARY_GRID_TOP_PADDING 39.0f

@interface SpringboardViewController (Private)

- (void)setupSearchController;

@end


@implementation SpringboardViewController

@synthesize searchResultsTableView, activeModule;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        activeModule = nil;
        completedModules = nil;
    }
    return self;
}

- (void)layoutIcons:(NSArray *)icons horizontalSpacing:(CGFloat)spacing {
    
    CGSize viewSize = containingView.frame.size;
    
    // figure out number of icons per row to fit on screen
    SpringboardIcon *anIcon = [icons objectAtIndex:0];
    CGSize iconSize = anIcon.frame.size;

    NSInteger iconsPerRow = (int)floor((viewSize.width - spacing) / (iconSize.width + spacing));
    div_t result = div([icons count], iconsPerRow);
    NSInteger numRows = (result.rem == 0) ? result.quot : result.quot + 1;
    CGFloat rowHeight = anIcon.frame.size.height + GRID_VPADDING;

    if ((rowHeight + GRID_VPADDING) * numRows > viewSize.height - GRID_VPADDING) {
        iconsPerRow++;
        CGFloat iconWidth = floor((viewSize.width - spacing) / iconsPerRow) - spacing;
        iconSize.height = floor(iconSize.height * (iconWidth / iconSize.width));
        iconSize.width = iconWidth;
    }
    
    // calculate xOrigin to keep icons centered
    CGFloat xOriginInitial = floor((viewSize.width - ((iconSize.width + spacing) * iconsPerRow - spacing)) / 2);
    CGFloat xOrigin = xOriginInitial;
    
    for (anIcon in icons) {
        anIcon.frame = CGRectMake(xOrigin, bottomRight.y, iconSize.width, iconSize.height);
        
        xOrigin += anIcon.frame.size.width + spacing;
        if (xOrigin + anIcon.frame.size.width + spacing > viewSize.width) {
            xOrigin = xOriginInitial;
            bottomRight.y += anIcon.frame.size.height + GRID_VPADDING;
        }
        
        if (![anIcon isDescendantOfView:containingView]) {
            [containingView addSubview:anIcon];
        }

        if (bottomRight.x < xOrigin + anIcon.frame.size.width) {
            bottomRight.x = xOrigin + anIcon.frame.size.width;
        }        
    }
    
    if (xOrigin > xOriginInitial) {
        bottomRight.y += iconSize.height + GRID_VPADDING;
    }

    // uncomment if we have so many icons that we need to scroll
    if (bottomRight.y > containingView.contentSize.height) {
        containingView.contentSize = CGSizeMake(containingView.contentSize.width, bottomRight.y);
    }

}

- (void)loadView {
    [super loadView];
    
    //UIBarButtonItem *editButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
    //                                                                             target:self
    //                                                                             action:@selector(customizeIcons:)] autorelease];
    //self.navigationItem.rightBarButtonItem = editButton;
    
    
    NSArray *modules = ((KGOAppDelegate *)[[UIApplication sharedApplication] delegate]).modules;
    _icons = [[NSMutableArray alloc] initWithCapacity:[modules count]];
    _fixedIcons = [[NSMutableArray alloc] init];
    
    for (KGOModule *aModule in modules) {
        SpringboardIcon *anIcon = [SpringboardIcon buttonWithType:UIButtonTypeCustom];
		UIImage *image = [[aModule iconImage] stretchableImageWithLeftCapWidth:0.0 topCapHeight:0.0];
        if (image) {
                        
            anIcon.frame = CGRectMake(0, 0, image.size.width + ICON_PADDING * 2, image.size.height + ICON_LABEL_HEIGHT);
            anIcon.imageEdgeInsets = UIEdgeInsetsMake(0, ICON_PADDING, ICON_LABEL_HEIGHT, ICON_PADDING);
            
            [anIcon setImage:image forState:UIControlStateNormal];

            UIFont *font = [UIFont systemFontOfSize:12.0];
            
            anIcon.titleLabel.numberOfLines = 0;
            anIcon.titleLabel.font = font;
            anIcon.titleLabel.textColor = [UIColor colorWithHexString:@"#403F3E"];
            anIcon.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
            anIcon.titleLabel.textAlignment = UITextAlignmentCenter;

            // TODO: add config setting for icon titles to be displayed on springboardewi
            [anIcon setTitle:aModule.longName forState:UIControlStateNormal];
            
            if (!aModule.secondary) {
                [_icons addObject:anIcon];
                // title by default is placed to the right of the image, we want it below
                CGSize labelSize = [aModule.longName sizeWithFont:font constrainedToSize:image.size lineBreakMode:UILineBreakModeWordWrap];

                //anIcon.titleEdgeInsets = UIEdgeInsetsMake(image.size.height, -image.size.width + 5.0, 0, 5.0);
                // a bit of fudging here... 12 is the font size of the title label
                anIcon.titleEdgeInsets = UIEdgeInsetsMake(image.size.height - 12.0 + floor(labelSize.height / 2), -image.size.width + 5.0, 0, 5.0);
                
            } else {
                [_fixedIcons addObject:anIcon];
                // title by default is placed to the right of the image, we want it below
                anIcon.titleEdgeInsets = UIEdgeInsetsMake(image.size.height + ICON_PADDING, -image.size.width - 5.0, 0, -5.0);
            }

            [anIcon setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            
            anIcon.moduleTag = aModule.tag;
            [anIcon addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
            
        } else {
            DLog(@"skipping module %@", aModule.tag);
        }
        // Add properties for accessibility/automation visibility.
        anIcon.isAccessibilityElement = YES;
        anIcon.accessibilityLabel = aModule.longName;
    }
    
}

- (void)viewDidLoad
{
	UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStyleBordered target:nil action:nil];	
	[[self navigationItem] setBackBarButtonItem: newBackButton];
	[newBackButton release];
    
    UIImage *masthead = [UIImage imageNamed:@"home/home-masthead.png"];
    self.navigationItem.titleView = [[[UIImageView alloc] initWithImage:masthead] autorelease];
    
    containingView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    containingView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:ImageNameHomeScreenBackground]];
    containingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:containingView];

    //_searchBar = [[KGOSearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    _searchBar = [[KGOSearchBar defaultSearchBarWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)] retain];
    _searchBar.placeholder = [NSString stringWithString:@"Search Harvard Mobile"];
    [self.view addSubview:_searchBar];

    bottomRight = CGPointZero;
    bottomRight.y = _searchBar.frame.size.height + GRID_VPADDING + GRID_TOP_MARGIN;
    [self layoutIcons:_icons horizontalSpacing:MAIN_GRID_HPADDING];

    bottomRight.y += SECONDARY_GRID_TOP_PADDING;
    [self layoutIcons:_fixedIcons horizontalSpacing:SECONDARY_GRID_HPADDING];
    
    [self setupSearchController];
}

- (void)setupSearchController {
    if (!_searchController) {
        _searchController = [[KGOSearchDisplayController alloc] initWithSearchBar:_searchBar delegate:self contentsController:self];
    }
}

- (void)buttonPressed:(id)sender {
    SpringboardIcon *anIcon = (SpringboardIcon *)sender;
    KGOAppDelegate *appDelegate = (KGOAppDelegate *)[[UIApplication sharedApplication] delegate];
    activeModule = [appDelegate moduleForTag:anIcon.moduleTag];
    UIViewController *viewController = [activeModule moduleHomeScreenWithParams:nil];
    [self.navigationController pushViewController:viewController animated:YES];

    // tracking
    NSString *detailString = [NSString stringWithFormat:@"/%@", anIcon.moduleTag];
    [[AnalyticsWrapper sharedWrapper] trackPageview:detailString];
}

- (void)viewWillAppear:(BOOL)animated {
    if (isSearch) {
        //[activeModule restoreNavStack];
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [_searchController release];
    _searchController = nil;
}

- (void)dealloc {
    [_icons release];
    [_fixedIcons release];
    [containingView release];
    [_searchBar release];
    [_searchController release];
    [completedModules release];
    [super dealloc];
}

#pragma mark KGOSearchDisplayDelegate

- (BOOL)searchControllerShouldShowSuggestions:(KGOSearchDisplayController *)controller {
    return YES;
}

- (NSArray *)searchControllerValidModules:(KGOSearchDisplayController *)controller {
    NSMutableArray *searchableModules = [NSMutableArray arrayWithCapacity:4];
    NSArray *modules = ((KGOAppDelegate *)[[UIApplication sharedApplication] delegate]).modules;
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
    if ([aResult isKindOfClass:[PersonDetails class]]) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:aResult, @"personDetails", nil];
        didShow = [(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] showPage:LocalPathPageNameDetail forModuleTag:PeopleTag params:params];
    }
    
    if (!didShow) {
        NSLog(@"springboard failed to respond to search result %@", [aResult description]);
    }
}

#pragma mark UIResponder / icon drag&drop

- (void)customizeIcons:(id)sender {
    CGRect frame = CGRectMake(0, 0, containingView.frame.size.width, containingView.frame.size.height);
    transparentOverlay = [[UIView alloc] initWithFrame:frame];
    transparentOverlay.backgroundColor = [UIColor clearColor];
    [containingView addSubview:transparentOverlay];
    
    UIBarButtonItem *doneButton = [[[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                    style:UIBarButtonItemStyleDone
                                                                   target:self
                                                                   action:@selector(endCustomize)] autorelease];
    navigationBar.topItem.rightBarButtonItem = doneButton;
    
    editing = YES;
    editedIcons = [_icons copy];
    [self becomeFirstResponder];
}

- (void)endCustomize {
    _icons = editedIcons;
    [transparentOverlay removeFromSuperview];
    [transparentOverlay release];
    
    UIBarButtonItem *editButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                 target:self
                                                                                 action:@selector(customizeIcons:)] autorelease];
    navigationBar.topItem.rightBarButtonItem = editButton;
    
    [self resignFirstResponder];
    editing = NO;
}

@end



@implementation SpringboardIcon

@synthesize moduleTag;

@end


