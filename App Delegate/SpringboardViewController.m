#import "SpringboardViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "MITModuleList.h"
#import "MITUIConstants.h"

#define GRID_HPADDING 12.0f
#define GRID_VPADDING 8.0f
#define ICON_LABEL_HEIGHT 26.0f

@implementation SpringboardViewController

@synthesize searchResultsTableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        activeModule = nil;
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
    CGFloat yOrigin = _searchBar.frame.size.height + GRID_VPADDING + 16.0;
    bottomRight = CGPointZero;
    
    for (anIcon in icons) {
        anIcon.frame = CGRectMake(xOrigin, yOrigin, iconSize.width, iconSize.height);
        bottomRight.y = yOrigin + anIcon.frame.size.height;
        
        xOrigin += anIcon.frame.size.width + GRID_HPADDING;
        if (xOrigin + anIcon.frame.size.width + GRID_HPADDING >= viewSize.width) {
            xOrigin = xOriginInitial;
            yOrigin += anIcon.frame.size.height + GRID_VPADDING;
        }
        
        if (![anIcon isDescendantOfView:containingView]) {
            [containingView addSubview:anIcon];
        }

        if (bottomRight.x < xOrigin + anIcon.frame.size.width) {
            bottomRight.x = xOrigin + anIcon.frame.size.width;
        }        
    }
    
    topLeft = ((SpringboardIcon *)[icons objectAtIndex:0]).frame.origin;

    if (bottomRight.y > containingView.contentSize.height) {
        containingView.contentSize = CGSizeMake(containingView.contentSize.width, bottomRight.y + GRID_VPADDING + 20.0);
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
    
    for (MITModule *aModule in modules) {
        SpringboardIcon *anIcon = [SpringboardIcon buttonWithType:UIButtonTypeCustom];
        UIImage *image = [aModule icon];
        if (image) {
            anIcon.frame = CGRectMake(0, 0, image.size.width, image.size.height + ICON_LABEL_HEIGHT);
            
            anIcon.imageEdgeInsets = UIEdgeInsetsMake(0, 0, ICON_LABEL_HEIGHT, 0);
            [anIcon setImage:image forState:UIControlStateNormal];
            
            // title by default is placed to the right of the image, we want it below
            anIcon.titleEdgeInsets = UIEdgeInsetsMake(image.size.height, -image.size.width, 0, 0);
            [anIcon setTitle:aModule.shortName forState:UIControlStateNormal];
            [anIcon setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [anIcon setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
            anIcon.titleLabel.font = [UIFont boldSystemFontOfSize:13.0];
            
            anIcon.moduleTag = aModule.tag;
            [anIcon addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
            [_icons addObject:anIcon];
        } else {
            NSLog(@"skipping module %@", aModule.tag);
        }
        // Add properties for accessibility/automation visibility.
        anIcon.isAccessibilityElement = YES;
        anIcon.accessibilityLabel = aModule.iconName;
    }
    
}

- (void)viewDidLoad
{
    self.navigationItem.title = @"Home";
    
    containingView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    containingView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:ImageNameHomeScreenBackground]];
    containingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:containingView];

    _searchBar = [[ModoSearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    _searchBar.delegate = self;
    [self.view addSubview:_searchBar];

    [self layoutIcons:_icons];
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
        [activeModule resetNavStack];
    }
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [_icons release];
    [containingView release];
    [_searchBar release];
    [super dealloc];
}

#pragma mark Search Bar delegation

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
    [searchBar setShowsScopeBar:YES];
    searchBar.scopeButtonTitles = [NSArray arrayWithObjects:@"one", @"two", @"three", nil];
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    return YES;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];
    if (!self.searchResultsTableView) {
        CGRect frame = CGRectMake(0, _searchBar.frame.size.height, self.view.frame.size.width,
                                  self.view.frame.size.height - _searchBar.frame.size.height);
        self.searchResultsTableView = [[[UITableView alloc] initWithFrame:frame style:UITableViewStyleGrouped] autorelease];
        self.searchResultsTableView.dataSource = self;
        self.searchResultsTableView.delegate = self;
        //[self.searchResultsTableView applyStandardColors];
    }
    [self.view addSubview:self.searchResultsTableView];
    [self searchAllModules];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchDidMakeProgress:) name:@"SearchResultsProgressNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchDidComplete:) name:@"SearchResultsCompleteNotification" object:nil];
}

- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar {
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];
    [self.searchResultsTableView removeFromSuperview];
    self.searchResultsTableView = nil;
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar {
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
}

#pragma mark Federated search

- (void)searchDidMakeProgress:(NSNotification *)aNotification {
    MITModule *sender = [aNotification object];
    NSInteger section = [self.searchableModules indexOfObject:sender];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
    [searchResultsTableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
}

- (void)searchDidComplete:(NSNotification *)aNotification {
    MITModule *sender = [aNotification object];
    NSInteger section = [self.searchableModules indexOfObject:sender];
    NSIndexSet *sections = [NSIndexSet indexSetWithIndex:section];
    [searchResultsTableView reloadSections:sections withRowAnimation:UITableViewRowAnimationNone];
}

- (void)searchAllModules {
    for (MITModule *aModule in self.searchableModules) {
        if (!aModule.isSearching) {
            [aModule performSearchForString:_searchBar.text];
        }
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.searchableModules count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    MITModule *aModule = [self.searchableModules objectAtIndex:indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    if (indexPath.row == 0) {
        UIActivityIndicatorView *spinny = (UIActivityIndicatorView *)[cell.contentView viewWithTag:1234];
        if (spinny != nil) {
            [spinny stopAnimating];
            [spinny removeFromSuperview];
        }
    }
    
    if (aModule.searchProgress == 1.0) {
        cell.imageView.image = nil;

        // TODO: add result count -- either in the cell header or after "more results"
        if (indexPath.row == MAX_FEDERATED_SEARCH_RESULTS) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = @"More results";
            cell.detailTextLabel.text = nil;
            
        } else if (![aModule.searchResults count]) {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.text = @"No results";
            cell.detailTextLabel.text = nil;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

        } else {
            id aResult = [aModule.searchResults objectAtIndex:indexPath.row];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.text = [aModule titleForSearchResult:aResult];
            cell.detailTextLabel.text = [aModule subtitleForSearchResult:aResult];
        }

    } else if (aModule.searchProgress == 0.0) {
        // indeterminate loading indicator
        cell.textLabel.text = @"Loading...";
        cell.detailTextLabel.text = nil;
        
        // copied from shuttles module
        cell.imageView.image = [UIImage imageNamed:@"shuttles/shuttle-blank.png"];
        UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        spinny.center = CGPointMake(18.0, 22.0);
        spinny.tag = 1234;
        [spinny startAnimating];
        [cell.contentView addSubview:spinny];
        [spinny release];
        
    } else {
        // determinate loading indicator
        cell.imageView.image = nil;
        cell.textLabel.text = [NSString stringWithFormat:@"%.0f%% complete", aModule.searchProgress * 100];
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
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return GROUPED_SECTION_HEADER_HEIGHT;
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


