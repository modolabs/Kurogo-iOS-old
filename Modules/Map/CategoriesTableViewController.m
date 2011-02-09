#import "CategoriesTableViewController.h"
#import "MapSelectionController.h"
#import "MapSearchResultAnnotation.h"
#import "CampusMapViewController.h"
#import "MITUIConstants.h"
#import "KGOSearchBar.h"
#import "KGOSearchDisplayController.h"

@implementation CategoriesTableViewController
@synthesize mapSelectionController = _mapSelectionController;
@synthesize itemsInTable = _itemsInTable;
@synthesize headerText = _headerText;
@synthesize category;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];
	
	[self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
	self.navigationItem.rightBarButtonItem = self.mapSelectionController.cancelButton;
	
    if (!_loadingView) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _loadingView = [[[MITLoadingActivityView alloc] initWithFrame:self.tableView.frame] retain];
        [self.view addSubview:_loadingView];
    }
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

- (void)dealloc {
	[_itemsInTable release];
	[_headerText release];
    [super dealloc];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _itemsInTable.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.textLabel.textColor = [[KGOTheme sharedTheme] textColorForTableCellTitleWithStyle:KGOTableCellStyleDefault];
		cell.textLabel.font = [[KGOTheme sharedTheme] fontForTableCellTitleWithStyle:KGOTableCellStyleDefault];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
	if ([[_itemsInTable objectAtIndex:indexPath.row] objectForKey:@"categoryName"]) {
		cell.textLabel.text = [[_itemsInTable objectAtIndex:indexPath.row] objectForKey:@"categoryName"];
	} else {
		NSString *displayName = [[_itemsInTable objectAtIndex:indexPath.row] objectForKey:@"displayName"];
        cell.textLabel.text = displayName;
	}

    return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	NSDictionary *thisItem = [_itemsInTable objectAtIndex:indexPath.row];
    
    // make sure the map is showing. 
    [self.mapSelectionController.mapVC showListView:NO];
    self.mapSelectionController.mapVC.searchBar.text = nil;

    NSMutableArray *searchResultsArray = [NSMutableArray array];
    
    ArcGISMapAnnotation *annotation = [[[ArcGISMapAnnotation alloc] initWithInfo:thisItem] autorelease];
    if (!annotation.dataPopulated) {
        [annotation searchAnnotationWithDelegate:self.mapSelectionController.mapVC category:self.category];
    }
    [searchResultsArray addObject:annotation];
    
    // this will remove any old annotations and add the new ones. 
    [self.mapSelectionController.mapVC setSearchResults:searchResultsArray];
    self.mapSelectionController.mapVC.searchBar.text = annotation.name;
    
    // in case they still have the overlay up from another search
    [self.mapSelectionController.mapVC.searchController hideSearchOverlayAnimated:NO];
    
    // on the map, select the current annotation
    [[self.mapSelectionController.mapVC mapView] selectAnnotation:annotation animated:NO];
    
    [self dismissModalViewControllerAnimated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 60;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (!_headerView) {
        CGFloat headerWidth = self.view.frame.size.width;
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, headerWidth, 60)];

		UILabel *headerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(16, 10, 200, 40)] autorelease];
		headerLabel.text = [NSString stringWithFormat:@"%@:", self.headerText];
		headerLabel.font = [UIFont boldSystemFontOfSize:16];
		headerLabel.textColor = [UIColor darkGrayColor];
		headerLabel.numberOfLines = 0;
		headerLabel.backgroundColor = [UIColor clearColor];
		[_headerView addSubview:headerLabel];
        _headerView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];

        UIButton* viewAllButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage* viewAllImage = [UIImage imageNamed:@"maps/map_viewall.png"];
        viewAllButton.frame = CGRectMake(headerWidth - viewAllImage.size.width - 10, 10, viewAllImage.size.width, viewAllImage.size.height);
        [viewAllButton setImage:viewAllImage forState:UIControlStateNormal];
        [viewAllButton setImage:[UIImage imageNamed:@"maps/map_viewall_pressed.png"] forState:UIControlStateHighlighted];
        [viewAllButton addTarget:self action:@selector(mapAllButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [_headerView addSubview:viewAllButton];
	}
	return _headerView;
}


#pragma mark MapAll
-(void) mapAllButtonTapped
{
	// make sure the map is showing. 
	[self.mapSelectionController.mapVC showListView:NO];
	
	// clear the search bar
	self.mapSelectionController.mapVC.searchBar.text = nil;
	
	NSMutableArray* searchResultsArray = [NSMutableArray array];
	
	for (NSDictionary *thisItem in _itemsInTable) {
		ArcGISMapAnnotation *annotation = [[[ArcGISMapAnnotation alloc] initWithInfo:thisItem] autorelease];
        if (!annotation.dataPopulated) {
            [annotation searchAnnotationWithDelegate:self.mapSelectionController.mapVC category:self.category];
        }
		[searchResultsArray addObject:annotation];
	}

	// this will remove any old annotations and add the new ones. 
	[self.mapSelectionController.mapVC setSearchResults:searchResultsArray];
    self.mapSelectionController.mapVC.searchBar.text = self.headerText;
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark JSONAPIDelegate
- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)JSONObject
{
    if (JSONObject && [JSONObject isKindOfClass:[NSArray class]]) {
        NSArray *categoryResults = JSONObject;
        
        _itemsInTable = [categoryResults retain];
        
        if (_loadingView) {
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
            [_loadingView removeFromSuperview];
            [_loadingView release];
            _loadingView = nil;
            
            self.tableView.backgroundColor = [UIColor whiteColor];
        }
        
        [self.tableView reloadData];
    }
}

- (BOOL)request:(JSONAPIRequest *)request shouldDisplayAlertForError:(NSError *)error {
    return YES;
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error
{
	if (_loadingView) {
		[_loadingView removeFromSuperview];
		[_loadingView release];
		_loadingView = nil;
	}
}

- (void)executeServerCategoryRequest 
{
	JSONAPIRequest *apiRequest = [JSONAPIRequest requestWithJSONAPIDelegate:self];
	[apiRequest requestObjectFromModule:@"map"
                                command:@"search"
                             parameters:[NSDictionary dictionaryWithObjectsAndKeys:self.category, @"category", nil]];
}




@end

