/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import "SpringboardViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "MITModuleList.h"
#import "MITUIConstants.h"
#import "MITModule.h"
#import "ModoNavigationController.h"
#import "ModoNavigationBar.h"
#import "ModoSearchBar.h"
#import "MITSearchDisplayController.h"
#import "AnalyticsWrapper.h"
#import "FederatedSearchTableView.h"
#import "UIKit+MITAdditions.h"

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
    
    
    NSArray *modules = ((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]).modules;
    _icons = [[NSMutableArray alloc] initWithCapacity:[modules count]];
    _fixedIcons = [[NSMutableArray alloc] init];
    
    for (MITModule *aModule in modules) {
        SpringboardIcon *anIcon = [SpringboardIcon buttonWithType:UIButtonTypeCustom];
		UIImage *image = [[aModule icon] stretchableImageWithLeftCapWidth:0.0 topCapHeight:0.0];
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
            
            // special case for shuttletracker
            NSString *iconTitle = nil;
            if ([aModule.longName isEqualToString:@"ShuttleTracker"]) {
                iconTitle = @"Shuttle Tracker";
            } else {
                iconTitle = aModule.longName;
            }
            [anIcon setTitle:iconTitle forState:UIControlStateNormal];
            
            if (aModule.canBecomeDefault) {
                [_icons addObject:anIcon];
                // title by default is placed to the right of the image, we want it below
                CGSize labelSize = [iconTitle sizeWithFont:font constrainedToSize:image.size lineBreakMode:UILineBreakModeWordWrap];

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
        anIcon.accessibilityLabel = aModule.iconName;
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

    _searchBar = [[ModoSearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    _searchBar.placeholder = [NSString stringWithString:@"Search Harvard Mobile"];
    [self.view addSubview:_searchBar];
    [_searchBar addDropShadow];

    bottomRight = CGPointZero;
    bottomRight.y = _searchBar.frame.size.height + GRID_VPADDING + GRID_TOP_MARGIN;
    [self layoutIcons:_icons horizontalSpacing:MAIN_GRID_HPADDING];

    bottomRight.y += SECONDARY_GRID_TOP_PADDING;
    [self layoutIcons:_fixedIcons horizontalSpacing:SECONDARY_GRID_HPADDING];
    
    [self setupSearchController];
}

- (void)setupSearchController {
    if (!_searchController) {
        _searchController = [[MITSearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
        _searchController.delegate = self;
        
        CGRect frame = CGRectMake(0, _searchBar.frame.size.height, containingView.frame.size.width,
                                  containingView.frame.size.height - _searchBar.frame.size.height);
        self.searchResultsTableView = [[[FederatedSearchTableView alloc] initWithFrame:frame style:UITableViewStylePlain] autorelease];
		self.searchResultsTableView.searchableModules = self.searchableModules;
        self.searchResultsTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.searchResultsTableView.hidden = YES;
        //[self.view addSubview:self.searchResultsTableView];
		[self addTableView:self.searchResultsTableView withDataSource:self.searchResultsTableView];
        
        _searchController.searchResultsTableView = self.searchResultsTableView;
        _searchController.searchResultsDelegate = self;
        _searchController.searchResultsDataSource = self;
    }
}

- (void)buttonPressed:(id)sender {
    SpringboardIcon *anIcon = (SpringboardIcon *)sender;
    if ([anIcon.moduleTag isEqualToString:MobileWebTag]) {
        // TODO: add this string to config
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.harvard.edu/?fullsite=yes"]];
    } else {
        MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
        activeModule = [appDelegate moduleForTag:anIcon.moduleTag];
        [appDelegate showModuleForTag:anIcon.moduleTag];
    }
    NSString *detailString = [NSString stringWithFormat:@"/%@", anIcon.moduleTag];
    [[AnalyticsWrapper sharedWrapper] trackPageview:detailString];
}

- (void)viewWillAppear:(BOOL)animated {
    if (isSearch) {
        [activeModule restoreNavStack];
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

#pragma mark Search Bar delegation

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self setupSearchController];
    
    // see the comment in -[setupSearchController] for why we do this
    //[self.searchResultsTableView removeFromSuperview];
    self.searchResultsTableView.hidden = NO;
	self.searchResultsTableView.query = searchBar.text;
    //[self.view addSubview:self.searchResultsTableView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchDidMakeProgress:) name:@"SearchResultsProgressNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchDidComplete:) name:@"SearchResultsCompleteNotification" object:nil];
    [completedModules release];
    completedModules = [[NSMutableArray alloc] initWithCapacity:[searchableModules count]];
    [self searchAllModules];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    isSearch = NO;
    for (MITModule *aModule in self.searchableModules) {
        [aModule abortSearch];
    }
}

#pragma mark Federated search

- (void)searchDidMakeProgress:(NSNotification *)aNotification {
    MITModule *sender = [aNotification object];
    if (![completedModules containsObject:sender]) {
        NSInteger section = [self.searchableModules indexOfObject:sender];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
        NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
        [searchResultsTableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)searchDidComplete:(NSNotification *)aNotification {
    @synchronized(self) {
        MITModule *sender = [aNotification object];
        NSInteger section = [self.searchableModules indexOfObject:sender];
        NSIndexSet *sections = [NSIndexSet indexSetWithIndex:section];
        [completedModules addObject:sender];
        [searchResultsTableView reloadSections:sections withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)searchAllModules {
    isSearch = YES;
    
    for (MITModule *aModule in self.searchableModules) {
        if (!aModule.isSearching) {
            [aModule performSearchForString:_searchBar.text];
        }
    }

	/*
    // an unfortunate hack because the tableview doesn't
    // remove section headers properly after multiple searches
    for (UIView *aView in [self.searchResultsTableView subviews]) {
        [aView removeFromSuperview];
    }
    */
    [self.searchResultsTableView reloadData];
}

- (NSArray *)searchableModules {
    if (!searchableModules) {
        searchableModules = [[NSMutableArray alloc] initWithCapacity:4];
        NSArray *modules = ((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]).modules;
        for (MITModule *aModule in modules) {
            if (aModule.supportsFederatedSearch) {
                [searchableModules addObject:aModule];
            }
        }
    }
    return searchableModules;
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

/*
- (BOOL)canBecomeFirstResponder {
    return editing;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([touches count] == 1) {
        selectedIcon = nil;
        UITouch *aTouch = [touches anyObject];
        for (SpringboardIcon *anIcon in editedIcons) {
            CGPoint point = [aTouch locationInView:containingView];
            CGFloat xOffset = point.x - anIcon.frame.origin.x;
            CGFloat yOffset = point.y - anIcon.frame.origin.y;
            if (xOffset > 0 && yOffset > 0
                && xOffset < anIcon.frame.size.width
                && yOffset < anIcon.frame.size.height)
            {
                selectedIcon = anIcon;
                startingPoint = anIcon.center;
                break;
            }
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (selectedIcon) {
        
        NSArray *array = _icons;
        if (editedIcons) {
            [editedIcons removeObjectAtIndex:dummyIconIndex];
            [editedIcons insertObject:selectedIcon atIndex:dummyIconIndex];
            //editedIcons = tempIcons;
            array = editedIcons;
        }
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        [self layoutIcons:array];
        [UIView commitAnimations];

        //tempIcons = nil;
    }
    selectedIcon = nil;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (selectedIcon) {
        UITouch *aTouch = [touches anyObject];
        
        CGPoint before = [aTouch previousLocationInView:containingView];
        CGPoint after = [aTouch locationInView:containingView];
        
        CGFloat xTransition = after.x - before.x;
        CGFloat yTransition = after.y - before.y;

        selectedIcon.frame = CGRectMake(selectedIcon.frame.origin.x + xTransition,
                                        selectedIcon.frame.origin.y + yTransition,
                                        selectedIcon.frame.size.width, selectedIcon.frame.size.height);

        xTransition = selectedIcon.center.x - startingPoint.x;
        yTransition = selectedIcon.center.y - startingPoint.y;
        
        if (fabs(xTransition) > selectedIcon.frame.size.width
            || fabs(yTransition) > selectedIcon.frame.size.height)
        { // don't do anything if they didn't move far
            tempIcons = [editedIcons mutableCopy];
            [tempIcons removeObject:selectedIcon];
            [tempIcons removeObject:dummyIcon];
            
            dummyIcon = [SpringboardIcon buttonWithType:UIButtonTypeCustom];
            dummyIcon.frame = selectedIcon.frame;

            // just figure out where in the array to stick selectedIcon
            dummyIconIndex = 0;
            for (SpringboardIcon *anIcon in tempIcons) {
                CGFloat xDistance = anIcon.center.x - selectedIcon.center.x; // > 0 if aButton is to the right
                CGFloat yDistance = selectedIcon.center.y - anIcon.center.y;
                NSLog(@"%d %.1f %.1f %.1f %.1f", dummyIconIndex, xDistance, GRID_HPADDING + anIcon.frame.size.width, yDistance, anIcon.frame.size.height / 2);// , aButton.center.x, selectedIcon.center.x);
                if (xDistance > 0 && xDistance < GRID_HPADDING + anIcon.frame.size.width
                    && fabs(yDistance) < anIcon.frame.size.height / 2) {
                    break;
                }
                dummyIconIndex++;
            }
            
            [tempIcons insertObject:dummyIcon atIndex:dummyIconIndex];
            NSLog(@"moving: to %d", dummyIconIndex);

            editedIcons = tempIcons;
            tempIcons = nil;
            
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.2];
            [self layoutIcons:editedIcons];
            [UIView commitAnimations];
        }
    }
}
*/
@end



@implementation SpringboardIcon

@synthesize moduleTag;

@end


