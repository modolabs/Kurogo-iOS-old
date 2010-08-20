#import "StellarClassesViewController.h"
#import "StellarCoursesViewController.h"
#import "StellarDetailViewController.h"
#import "StellarClassTableCell.h"
#import "MITModuleList.h"
#import "MITModule.h"
#import "MITLoadingActivityView.h"
#import "UITableView+MITUIAdditions.h"
#import "MultiLineTableViewCell.h"
#import "ModoSearchBar.h"
#import "MITUIConstants.h"
#import "MITSearchDisplayController.h"

#define searchBarHeight NAVIGATION_BAR_HEIGHT

@interface StellarClassesViewController (Private)
- (void) alertViewCancel: (UIAlertView *)alertView;
- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex: (NSInteger)buttonIndex;
@end

@implementation StellarClassesViewController
@synthesize classes, currentClassLoader;
@synthesize loadingView;
@synthesize url;

@synthesize searchController;
@synthesize doSearchTerms;

@synthesize harvardClassesTableView;

- (id) initWithCourse: (StellarCourse *)aCourse {
	//if (self = [super initWithStyle:UITableViewStylePlain]) {
	course = [aCourse retain];
	classes = [[NSArray array] retain];
	loadingView = nil;
	url = [[MITModuleURL alloc] initWithTag:StellarTag];
	//}
	
	NSString *courseName = [[NSString alloc] initWithFormat:@"%@-other",course.courseGroup];
	if ([course.title isEqualToString:courseName]) {
		self.navigationItem.title = course.courseGroupShort;
		self.title = course.courseGroupShort;
	}
	
	if ([aCourse.courseGroupShort isEqualToString:@"Business - Doctoral Program"]) { 
		UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle: @"HBS PhD" style: UIBarButtonItemStyleBordered target: nil action: nil];	
		[[self navigationItem] setBackBarButtonItem: newBackButton];
		[newBackButton release];
	}
	else if ([aCourse.courseGroupShort isEqualToString:@"Business - MBA Program"]) { 
		UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle: @"HBS MBA" style: UIBarButtonItemStyleBordered target: nil action: nil];	
		[[self navigationItem] setBackBarButtonItem: newBackButton];
		[newBackButton release];
	}
	
	return self;
}

- (void) dealloc {
	currentClassLoader.tableController = nil;
	[url release];
	[loadingView release];
	[currentClassLoader release];
	[classes release];
	[course release];
	[super dealloc];
}

- (void) showLoadingView {
	//self.tableView.tableHeaderView = loadingView;
	//self.tableView.backgroundColor = [UIColor clearColor];
	[self.view addSubview:loadingView];
	self.harvardClassesTableView.tableHeaderView = loadingView;
	self.harvardClassesTableView.backgroundColor = [UIColor clearColor];
}

- (void) hideLoadingView {
	//self.tableView.tableHeaderView = nil;
	//self.tableView.backgroundColor = [UIColor whiteColor];
	[loadingView removeFromSuperview];
	self.harvardClassesTableView.tableHeaderView = nil;
	self.harvardClassesTableView.backgroundColor = [UIColor whiteColor];
}

- (void) viewDidLoad {

    [super viewDidLoad];
	CGRect viewFrame = self.view.frame;
	ModoSearchBar *searchBar = [[[ModoSearchBar alloc] initWithFrame:CGRectMake(0, 0, viewFrame.size.width, searchBarHeight)] autorelease];
    [self.view addSubview:searchBar];
	
	self.searchController = [[[MITSearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self] autorelease];
    self.searchController.delegate = self;
	
	stellarSearch = [[StellarSearch alloc] initWithViewController:self];
	self.searchController.searchResultsDelegate = stellarSearch;
	self.searchController.searchResultsDataSource = stellarSearch;
	searchBar.placeholder = [[NSString alloc] initWithFormat:@"Search within %@", course.title];
	
	harvardClassesTableView = nil;
	
	harvardClassesTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, searchBarHeight, 320.0, 420.0) style: UITableViewStylePlain];
	harvardClassesTableView.backgroundColor = [UIColor whiteColor];
	self.view.backgroundColor = [UIColor whiteColor];
	harvardClassesTableView.delegate= self;
	harvardClassesTableView.dataSource = self;
	harvardClassesTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:harvardClassesTableView];
    
    [searchBar addDropShadow];
	
	NSString *courseName = [[NSString alloc] initWithFormat:@"%@-other",course.courseGroup];
	if ([course.title isEqualToString:courseName]) {
		self.navigationItem.title = course.courseGroupShort;
		self.title = course.courseGroupShort;
	}
	
	else if ([[course.title substringToIndex:1] isEqualToString:@"0"])
		self.title = [course.title substringFromIndex:1];
	
	else
		self.title = course.title;

	self.currentClassLoader = [[LoadClassesInTable new] autorelease];
	self.currentClassLoader.tableController = self;

	[harvardClassesTableView applyStandardCellHeight];

	self.loadingView = [[[MITLoadingActivityView alloc] initWithFrame:self.harvardClassesTableView.frame xDimensionScaling:2 yDimensionScaling:2.5] autorelease];	
	[self showLoadingView];
	
	[StellarModel loadClassesForCourse:course delegate:self.currentClassLoader];
	
	[url setPathWithViewController:self extension:course.number];
}

- (void) viewDidAppear: (BOOL)animated {
	[url setAsModulePath];
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *)tableView {
	return 1;
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StellarClasses"];
	if(cell == nil) {
		cell = [[[StellarClassTableCell alloc] initWithReusableCellIdentifier:@"StellarClasses"] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	
	StellarClass *stellarClass = [classes objectAtIndex:indexPath.row];
	StellarClass *stellarPreviousClass;
	StellarClass *stellarNextClass;
	
	if (indexPath.row > 0) {
		
		// Some logic to ensure that either the pevious or the next class is passed to the configurCell function
		stellarPreviousClass = [classes objectAtIndex:indexPath.row - 1];
		
		if ([classes count] > indexPath.row + 1) 
			stellarNextClass = [classes objectAtIndex:indexPath.row + 1];
		
		else
			stellarNextClass = stellarPreviousClass;
		
		if (![stellarPreviousClass.name isEqualToString:stellarClass.name])
			stellarPreviousClass = stellarNextClass;

	}
	else {
		if ([classes count] > 1)
			stellarPreviousClass = [classes objectAtIndex:indexPath.row + 1];
		
		else 
			stellarPreviousClass = nil;
	}

									
	return [StellarClassTableCell configureCell:cell withStellarClass:stellarClass previousClassInList:stellarPreviousClass];
}	

- (NSInteger) tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
	return [classes count];
}

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	[StellarDetailViewController 
	 launchClass:(StellarClass *)[classes objectAtIndex:indexPath.row]
	 viewController: self];
}

- (CGFloat) tableView: (UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath {
	//return [StellarClassTableCell cellHeightForTableView:tableView class:[classes objectAtIndex:indexPath.row]];
	
	StellarClass *stellarClass = [classes objectAtIndex:indexPath.row];
	StellarClass *stellarPreviousClass;
	
	if (indexPath.row > 0)
		stellarPreviousClass = [classes objectAtIndex:indexPath.row - 1];
	else {
		if ([classes count] > 1)
			stellarPreviousClass = [classes objectAtIndex:indexPath.row + 1];
		
		else 
			stellarPreviousClass = nil;
	}
	NSString *detail = (NSString *)[StellarClassTableCell setStaffNames:stellarClass previousClassInList:stellarPreviousClass];
	return [StellarClassTableCell cellHeightForTableView:tableView class:stellarClass detailString:detail];
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex: (NSInteger)buttonIndex {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) alertViewCancel: (UIAlertView *)alertView {
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark Search and search UI


- (void) searchBarSearchButtonClicked: (UISearchBar *)theSearchBar {
	[self showLoadingView];
	hasSearchInitiated = YES;
	[StellarModel executeStellarSearch:theSearchBar.text courseGroupName:course.courseGroup courseName:course.title delegate:stellarSearch];
	
	[self.url setPath:@"search-complete" query:theSearchBar.text];
	[self.url setAsModulePath];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    
	[self.url setPath:@"search-begin" query:nil];
	[self.url setAsModulePath];
    
    return YES;
}

- (void) searchBar: (UISearchBar *)searchBar textDidChange: (NSString *)searchText {
	[self hideLoadingView]; // just in case the loading view is showing
	
	hasSearchInitiated = NO;
	
	[self.url setPath:@"search-begin" query:searchText];
	[self.url setAsModulePath];
}

- (void) searchOverlayTapped {
	[self hideLoadingView];
	//[self reloadMyStellarUI];
	[harvardClassesTableView reloadData];
	
	[self.url setPath:@"" query:nil];
	[self.url setAsModulePath];
}

- (void)presentSearchResults:(NSArray *)searchResults query:(NSString *)query {
    self.searchController.searchBar.text = query;
    [stellarSearch searchComplete:searchResults searchTerms:query actualCount:0];
}

// TODO: clean up redundant -[searchBar becomeFirstResponder]
- (void) doSearch:(NSString *)searchTerms execute:(BOOL)execute {
	if(isViewAppeared) {
		self.searchController.active = YES;
		self.searchController.searchBar.text = searchTerms;
		if (execute) {
			self.searchController.searchBar.text = searchTerms;
			[stellarSearch performSelector:@selector(searchBarSearchButtonClicked:) withObject:self.searchController.searchBar afterDelay:0.3];
		} else {
			// using a delay gets rid of a mysterious wait_fences warning
			[self.searchController.searchBar performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.001];
		}
		self.doSearchTerms = nil;
	} else {
		// since view has not appeared yet, this search needs to be delay to either viewWillAppear or viewDidAppear
		// this is a work around for funky behavior when module is in the more list controller
		self.doSearchTerms = searchTerms;
		doSearchExecute = execute;
	}
}

- (void) showSearchResultsTable {
	[self.view addSubview:searchController.searchResultsTableView];
}


- (void) hideSearchResultsTable {
	[searchController.searchResultsTableView removeFromSuperview];
}

/* To make the complier happy */
-(void)reloadData {
}



@end


@implementation LoadClassesInTable
@synthesize tableController;

- (void) classesLoaded: (NSArray *)aClassList {
	if(tableController.currentClassLoader == self) {
		tableController.classes = aClassList;
		[tableController hideLoadingView];
		//[tableController.tableView reloadData];
		[tableController.harvardClassesTableView reloadData];
	}
}

- (void) handleCouldNotReachStellar {
	if(tableController.currentClassLoader == self) {
		[tableController hideLoadingView];
		
		UIAlertView *alert = [[UIAlertView alloc] 
							  initWithTitle:@"Connection Failed" 
							  message:[NSString stringWithFormat:@"Could not connect to retrieve classes for %@, please try again later", tableController.title]
							  delegate:tableController
							  cancelButtonTitle:@"OK" 
							  otherButtonTitles:nil];
		[alert show];
        [alert release];
	}
}
@end