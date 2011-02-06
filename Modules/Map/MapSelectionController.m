#import "MapSelectionController.h"
#import "CategoriesTableViewController.h"
#import "MapBookmarkManager.h"
#import "CoreDataManager.h"
#import "MapSavedAnnotation.h"
#import "MITUIConstants.h"
#import "MapSearchResultAnnotation.h"
#import "CampusMapViewController.h"
#import "MapSearch.h"
#import "AnalyticsWrapper.h"

@interface MapSelectionController (Private)

- (void)beginEditing;
- (void)endEditing;
- (void)hideLoadingView;

@end


@implementation MapSelectionController
@synthesize mapVC = _mapVC;
@synthesize cancelButton = _cancelButton;
@synthesize tableView = _tableView;
@synthesize tableItems = _tableItems;
@synthesize segControl;

- (void)viewDidLoad {
    [super viewDidLoad];

	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    
	self.segControl = [[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Bookmarks", @"Recents", @"Browse", nil]] autorelease];
	[segControl setSegmentedControlStyle:UISegmentedControlStyleBar];
	[segControl setFrame:CGRectMake(0, 0, self.view.frame.size.width - 30, segControl.frame.size.height)];
	[segControl setTintColor:[UIColor darkGrayColor]];
	[segControl addTarget:self action:@selector(switchToSegment:) forControlEvents:UIControlEventValueChanged];
	
	UIBarButtonItem *item = [[[UIBarButtonItem alloc] initWithCustomView:segControl] autorelease];
	
	[self.navigationController setToolbarHidden:NO];
	[self.navigationController.toolbar setBarStyle:UIBarStyleBlack];
    self.toolbarItems = [NSArray arrayWithObject:item];
    
    if (!_cancelButton) {
        _cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" 
                                                         style:UIBarButtonItemStyleBordered 
                                                        target:self 
                                                        action:@selector(cancelButtonTapped)];
    }
    
    self.hidesBottomBarWhenPushed = YES;
	self.navigationItem.rightBarButtonItem = _cancelButton;
	[self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    
    [self switchToSegmentIndex:MapSelectionControllerSegmentBrowse];
}

- (void)viewWillAppear:(BOOL)animated {
	[self.navigationController setToolbarHidden:NO];
}

- (void)dealloc
{
	self.mapVC = nil;
	[_cancelButton release];
    [_categoryItems release];
    self.tableView = nil;
    self.tableItems = nil;
	[super dealloc];
}


#pragma mark User Actions

- (void)cancelButtonTapped {
	[self dismissModalViewControllerAnimated:YES];
}


- (void)switchToSegment:(id)sender {
    
    UISegmentedControl *seg = (UISegmentedControl *)sender;
    MapSelectionControllerSegment segment = seg.selectedSegmentIndex;
    [self switchToSegmentIndex:segment];
}

- (void)switchToSegmentIndex:(MapSelectionControllerSegment)segment {

    self.segControl.selectedSegmentIndex = segment;
    [self hideLoadingView];
    
    if (_selectedSegment == segment) return;
    
    _selectedSegment = segment;
    
    [self.tableView removeFromSuperview];
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
	switch (_selectedSegment) {
		case MapSelectionControllerSegmentBookmarks:
        {
            self.navigationItem.title = @"Bookmarks";
            self.navigationItem.leftBarButtonItem = self.editButtonItem;
            self.editButtonItem.target = self;
            self.editButtonItem.action = @selector(beginEditing);
            
            self.tableView = [[[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain] autorelease];
            self.tableItems = [[MapBookmarkManager defaultManager] bookmarks];
            
            if ([self.tableItems count] <= 0) {
            	self.editButtonItem.enabled = NO;
            }
            
			break;
        }
		case MapSelectionControllerSegmentRecents:
        {
            self.navigationItem.title = @"Recent Searches";
            self.navigationItem.leftBarButtonItem = nil;
            
            self.tableView = [[[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain] autorelease];

            NSSortDescriptor* sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
            self.tableItems = [[CoreDataManager fetchDataForAttribute:CampusMapSearchEntityName sortDescriptor:sortDescriptor] retain];
            
			break;
        }
		case MapSelectionControllerSegmentBrowse:
        {
            self.navigationItem.title = @"Browse";
            self.navigationItem.leftBarButtonItem = nil;
            
            self.tableView = [[[UITableView alloc] initWithFrame:frame style:UITableViewStyleGrouped] autorelease];
            self.tableItems = _categoryItems;
            
            if (!self.tableItems) {
                JSONAPIRequest *apiRequest = [JSONAPIRequest requestWithJSONAPIDelegate:self];
                [apiRequest requestObjectFromModule:@"map" command:@"categorytitles" parameters:nil];
                
                if (!_loadingView) {
                    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
                    _loadingView = [[[MITLoadingActivityView alloc] initWithFrame:self.tableView.frame] retain];
                    [self.view addSubview:_loadingView];
                }
            }
            
			break;
        }
		default:
			break;
	}

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.view addSubview:self.tableView];
    [self.tableView reloadData];
    
    NSString *detailString = [NSString stringWithFormat:@"/map/%@", self.navigationItem.title];
    [[AnalyticsWrapper sharedWrapper] trackPageview:detailString];
}


#pragma mark JSONAPIDelegate

- (void)hideLoadingView {
    if (_loadingView) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        [_loadingView removeFromSuperview];
        [_loadingView release];
        _loadingView = nil;
    }
}

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)JSONObject
{
    if (_selectedSegment == MapSelectionControllerSegmentBrowse
        && JSONObject && [JSONObject isKindOfClass:[NSArray class]]) {

        _categoryItems = [[NSArray alloc] initWithArray:JSONObject];
        self.tableItems = _categoryItems;
        [self hideLoadingView];
        [self.tableView reloadData];
    }
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error
{
    [self hideLoadingView];
	
	UIAlertView *alert = [[[UIAlertView alloc]
                           initWithTitle:@"Connection Failed" 
                           message:@"Could not connect to server. Please try again later."
                           delegate:nil
                           cancelButtonTitle:@"OK" 
                           otherButtonTitles:nil] autorelease];
	[alert show];
    
	
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = [self.tableItems count];
    return rows;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		cell.textLabel.textColor = [[KGOTheme sharedTheme] textColorForTableCellTitleWithStyle:KGOTableCellStyleSubtitle];
		cell.textLabel.font = [[KGOTheme sharedTheme] fontForTableCellTitleWithStyle:KGOTableCellStyleSubtitle];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
	switch (_selectedSegment) {
		case MapSelectionControllerSegmentBookmarks:
        {
            MapSavedAnnotation *savedAnnotation = [self.tableItems objectAtIndex:indexPath.row];
            cell.textLabel.text = savedAnnotation.name;
            cell.detailTextLabel.text = savedAnnotation.street;
            cell.detailTextLabel.textColor = [[KGOTheme sharedTheme] textColorForTableCellSubtitleWithStyle:KGOTableCellStyleSubtitle];
            cell.detailTextLabel.font = [[KGOTheme sharedTheme] fontForTableCellSubtitleWithStyle:KGOTableCellStyleSubtitle];
			break;
        }
		case MapSelectionControllerSegmentRecents:
        {
            if (indexPath.row < self.tableItems.count) {
                MapSearch *search = [self.tableItems objectAtIndex:indexPath.row];
                cell.textLabel.text = search.searchTerm;
            }
			break;
        }
		case MapSelectionControllerSegmentBrowse:
        {
            if ([[self.tableItems objectAtIndex:indexPath.row] objectForKey:@"categoryName"]) {
                cell.textLabel.text = [[self.tableItems objectAtIndex:indexPath.row] objectForKey:@"categoryName"];
            } else {
                NSString *displayName = [[self.tableItems objectAtIndex:indexPath.row] objectForKey:@"displayName"];
                cell.textLabel.text = displayName;
            }
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.backgroundColor = [UIColor whiteColor];
			
            break;
        }
		default:
			break;
	}
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = nil;
    
    if (_selectedSegment == MapSelectionControllerSegmentBrowse && section == 0) {
        headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)] autorelease];
        UILabel* headerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(16, 10, 226, 40)] autorelease];
        headerLabel.text = [NSString stringWithString:@"Browse map by:"];;
        headerLabel.font = [UIFont boldSystemFontOfSize:16];
        headerLabel.textColor = [UIColor darkGrayColor];
        headerLabel.numberOfLines = 0;
        headerLabel.backgroundColor = [UIColor clearColor];
        [headerView addSubview:headerLabel];
    }
	return headerView;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
		MapSavedAnnotation *bookmark = [[[MapBookmarkManager defaultManager] bookmarks] objectAtIndex:indexPath.row];
		[[MapBookmarkManager defaultManager] removeBookmark:bookmark];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
		
        // turn off edit mode if they delete everything
		if ([[[MapBookmarkManager defaultManager] bookmarks] count] <= 0) {
			[self.tableView setEditing:NO animated:YES];
			self.editButtonItem.enabled = NO;
		}
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath 
{
	int fromRow = [fromIndexPath row];
	int toRow = [toIndexPath row];
	
	[[MapBookmarkManager defaultManager] moveBookmarkFromRow:fromRow toRow:toRow];
	
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return (_selectedSegment == MapSelectionControllerSegmentBookmarks);
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return (_selectedSegment == MapSelectionControllerSegmentBookmarks);
}

- (void)beginEditing {
    [self.tableView setEditing:YES animated:YES];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(endEditing)] autorelease];
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)endEditing {
    [self.tableView setEditing:NO animated:YES];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(beginEditing)] autorelease];
    self.navigationItem.rightBarButtonItem = _cancelButton;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (_selectedSegment == MapSelectionControllerSegmentBrowse) {
        return 60;
    }
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
	switch (_selectedSegment) {
		case MapSelectionControllerSegmentBookmarks:
        {
            MapSavedAnnotation *bookmark = [[[MapBookmarkManager defaultManager] bookmarks] objectAtIndex:indexPath.row];
            
            NSDictionary *info = [NSKeyedUnarchiver unarchiveObjectWithData:bookmark.info];
            ArcGISMapAnnotation *annotation = [[[ArcGISMapAnnotation alloc] initWithInfo:info] autorelease];
            
            [self.mapVC.mapView removeAnnotations:self.mapVC.mapView.annotations];
            [self.mapVC.mapView addAnnotation:annotation];
            [self.mapVC.mapView selectAnnotation:annotation animated:NO];
            
            [self.mapVC pushAnnotationDetails:annotation animated:NO];
            
            [self dismissModalViewControllerAnimated:YES];
            
			break;
        }
		case MapSelectionControllerSegmentRecents:
        {
            // determine the search term they selected. 
            MapSearch *search = [self.tableItems objectAtIndex:indexPath.row];
            
            self.mapVC.searchBar.text = search.searchTerm;
            [self.mapVC search:search.searchTerm params:nil];
            
            [self dismissModalViewControllerAnimated:YES];
            
			break;
        }
		case MapSelectionControllerSegmentBrowse:
        {
            NSDictionary* thisItem = [self.tableItems objectAtIndex:indexPath.row];

            CategoriesTableViewController *newCategoriesTVC = [[[CategoriesTableViewController alloc] init] autorelease];
            newCategoriesTVC.mapSelectionController = self;
            newCategoriesTVC.headerText = [thisItem objectForKey:@"categoryName"];
            newCategoriesTVC.category = [thisItem objectForKey:@"categoryId"];
            [newCategoriesTVC executeServerCategoryRequest];
            
            [self.navigationController pushViewController:newCategoriesTVC animated:YES];
            
			break;
        }
		default:
			break;
	}
}

@end
