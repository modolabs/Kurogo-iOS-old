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

// horizontal spacing between icons
#define GRID_HPADDING 17.0f

// vertical spacing between icons
#define GRID_VPADDING 24.0f

// height to allocate to icon text label
#define ICON_LABEL_HEIGHT 22.0f

// internal padding within each icon (allows longer text labels)
#define ICON_PADDING 5.0f

@interface SpringboardViewController (Private)

- (void)setupSearchController;

@end


@implementation SpringboardViewController

@synthesize searchResultsTableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        activeModule = nil;
        completedModules = nil;
    }
    return self;
}

- (void)layoutIcons:(NSArray *)icons {
    
    CGSize viewSize = containingView.frame.size;
    
    // figure out number of icons per row to fit on screen
    SpringboardIcon *anIcon = [icons objectAtIndex:0];
    CGSize iconSize = anIcon.frame.size;

    NSInteger iconsPerRow = (int)floor((viewSize.width - GRID_HPADDING) / (iconSize.width + GRID_HPADDING));
    div_t result = div([icons count], iconsPerRow);
    NSInteger numRows = (result.rem == 0) ? result.quot : result.quot + 1;
    CGFloat rowHeight = anIcon.frame.size.height + GRID_VPADDING;

    if ((rowHeight + GRID_VPADDING) * numRows > viewSize.height - GRID_VPADDING) {
        iconsPerRow++;
        CGFloat iconWidth = floor((viewSize.width - GRID_HPADDING) / iconsPerRow) - GRID_HPADDING;
        iconSize.height = floor(iconSize.height * (iconWidth / iconSize.width));
        iconSize.width = iconWidth;
    }
    
    // calculate xOrigin to keep icons centered
    CGFloat xOriginInitial = (viewSize.width - ((iconSize.width + GRID_HPADDING) * iconsPerRow - GRID_HPADDING)) / 2;
    CGFloat xOrigin = xOriginInitial;
    
    for (anIcon in icons) {
        anIcon.frame = CGRectMake(xOrigin, bottomRight.y, iconSize.width, iconSize.height);
        
        xOrigin += anIcon.frame.size.width + GRID_HPADDING;
        if (xOrigin + anIcon.frame.size.width + GRID_HPADDING >= viewSize.width) {
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
        UIImage *image = [aModule icon];
        if (image) {
            
            if (aModule.canBecomeDefault) {
                [_icons addObject:anIcon];
                // title by default is placed to the right of the image, we want it below
                anIcon.titleEdgeInsets = UIEdgeInsetsMake(image.size.height, -image.size.width, 0, 0);
            } else {
                [_fixedIcons addObject:anIcon];
                // title by default is placed to the right of the image, we want it below
                anIcon.titleEdgeInsets = UIEdgeInsetsMake(image.size.height + ICON_PADDING, -image.size.width - 5.0, 0, -5.0);
            }
            
            anIcon.frame = CGRectMake(0, 0, image.size.width + ICON_PADDING * 2, image.size.height + ICON_LABEL_HEIGHT);
            anIcon.imageEdgeInsets = UIEdgeInsetsMake(0, ICON_PADDING, ICON_LABEL_HEIGHT, ICON_PADDING);
            
            [anIcon setImage:image forState:UIControlStateNormal];

            anIcon.titleLabel.numberOfLines = 0;
            anIcon.titleLabel.font = [UIFont systemFontOfSize:12.0];
            anIcon.titleLabel.textColor = [UIColor colorWithHexString:@"#403F3E"];
            anIcon.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
            anIcon.titleLabel.textAlignment = UITextAlignmentCenter;
            
            [anIcon setTitle:aModule.longName forState:UIControlStateNormal];
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
    bottomRight.y = _searchBar.frame.size.height + GRID_VPADDING;
    [self layoutIcons:_icons];
    [self layoutIcons:_fixedIcons];
    
    [self setupSearchController];
}

- (void)setupSearchController {
    if (!_searchController) {
        _searchController = [[MITSearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
        _searchController.delegate = self;
        
        CGRect frame = CGRectMake(0, _searchBar.frame.size.height, containingView.frame.size.width,
                                  containingView.frame.size.height - _searchBar.frame.size.height);
        self.searchResultsTableView = [[[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain] autorelease];
        self.searchResultsTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        // we need to add searchResultsTableView as a subview for
        // autoresizing to happen properly.  we will set it to
        // visible and add/remove it the normal way after the
        // containing navigationController has been set up.
        self.searchResultsTableView.hidden = YES;
        [self.view addSubview:self.searchResultsTableView];
        
        _searchController.searchResultsTableView = self.searchResultsTableView;
        _searchController.searchResultsDelegate = self;
        _searchController.searchResultsDataSource = self;
    }
}

- (void)buttonPressed:(id)sender {
    SpringboardIcon *anIcon = (SpringboardIcon *)sender;
    if ([anIcon.moduleTag isEqualToString:MobileWebTag]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.harvard.edu"]];
    } else {
        MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
        activeModule = [appDelegate moduleForTag:anIcon.moduleTag];
        [appDelegate showModuleForTag:anIcon.moduleTag];
    }
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
    [self.searchResultsTableView removeFromSuperview];
    self.searchResultsTableView.hidden = NO;
    [self.view addSubview:self.searchResultsTableView];

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

    // an unfortunate hack because the tableview doesn't
    // remove section headers properly after multiple searches
    for (UIView *aView in [self.searchResultsTableView subviews]) {
        [aView removeFromSuperview];
    }
    
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

#pragma mark UITableView datasource

// TODO: don't waste space with modules that return no results
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.searchableModules count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    MITModule *aModule = [self.searchableModules objectAtIndex:indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    if (aModule.searchProgress == 1.0) {
        cell.imageView.image = nil;

        if (indexPath.row == MAX_FEDERATED_SEARCH_RESULTS) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = [NSString stringWithFormat:@"See all %d matches", [aModule totalSearchResults]];
            cell.detailTextLabel.text = nil;
            
        } else if (![aModule.searchResults count]) {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.text = @"No matches found.";
            cell.detailTextLabel.text = nil;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

        } else {
            id aResult = [aModule.searchResults objectAtIndex:indexPath.row];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.text = [aModule titleForSearchResult:aResult];
            cell.detailTextLabel.text = [aModule subtitleForSearchResult:aResult];
        }

    } else {
        
        // indeterminate loading indicator
        cell.textLabel.text = @"Searching...";
        cell.detailTextLabel.text = nil;
        
        // copied from shuttles module
        cell.imageView.image = [UIImage imageNamed:@"loading-animation/iPhoneBusybox_01.png"];
        DLog(@"%@", [cell.imageView.image description]);
        cell.imageView.animationImages = [NSArray arrayWithObjects:
                                          [UIImage imageNamed:@"loading-animation/iPhoneBusybox_01.png"],
                                          [UIImage imageNamed:@"loading-animation/iPhoneBusybox_02.png"],
                                          [UIImage imageNamed:@"loading-animation/iPhoneBusybox_03.png"],
                                          [UIImage imageNamed:@"loading-animation/iPhoneBusybox_04.png"],
                                          [UIImage imageNamed:@"loading-animation/iPhoneBusybox_05.png"],
                                          [UIImage imageNamed:@"loading-animation/iPhoneBusybox_06.png"],
                                          [UIImage imageNamed:@"loading-animation/iPhoneBusybox_07.png"],
                                          [UIImage imageNamed:@"loading-animation/iPhoneBusybox_08.png"],
                                          [UIImage imageNamed:@"loading-animation/iPhoneBusybox_09.png"],
                                          [UIImage imageNamed:@"loading-animation/iPhoneBusybox_10.png"],
                                          [UIImage imageNamed:@"loading-animation/iPhoneBusybox_11.png"],
                                          [UIImage imageNamed:@"loading-animation/iPhoneBusybox_12.png"],
                                          nil];
        [cell.imageView startAnimating];
        
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger num = 1;
    MITModule *aModule = [self.searchableModules objectAtIndex:section];
    if (aModule.searchProgress == 1.0) {
        num = [aModule.searchResults count];
        if (num > MAX_FEDERATED_SEARCH_RESULTS) {
            num = MAX_FEDERATED_SEARCH_RESULTS + 1; // one extra row for "more"
        } else if (num == 0) {
            num = 1;
        }
    }
    return num;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    MITModule *aModule = [self.searchableModules objectAtIndex:section];
    NSString *title = aModule.longName;
    return [UITableView ungroupedSectionHeaderWithTitle:title];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MITModule *aModule = [self.searchableModules objectAtIndex:indexPath.section];
    if ([aModule.searchResults count]) {
        activeModule = aModule;
        if (indexPath.row == MAX_FEDERATED_SEARCH_RESULTS) {
            [activeModule handleLocalPath:LocalPathFederatedSearch query:[NSString stringWithFormat:@"%@", _searchBar.text, indexPath.row]];
        } else {
            // TODO: decide whether the query string really needs to be passed to the module
            [activeModule handleLocalPath:LocalPathFederatedSearchResult query:[NSString stringWithFormat:@"%d", indexPath.row]];
        }
        MIT_MobileAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        [appDelegate showModuleForTag:activeModule.tag];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return UNGROUPED_SECTION_HEADER_HEIGHT;
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


