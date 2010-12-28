#import "StellarMainSearch.h"
#import "StellarClass.h"
#import "StellarDetailViewController.h"
#import "StellarMainTableController.h"
#import "StellarClassTableCell.h"
#import "UITableView+MITUIAdditions.h"
#import "MITUIConstants.h"
#import "MITSearchDisplayController.h"
#import "MultiLineTableViewCell.h"
#import "StellarSearch.h"
#import "MainSearchGroupedCoursesTableViewController.h"

@implementation StellarMainSearch

@synthesize lastResults;
@synthesize activeMode;
@synthesize groups;

- (BOOL) isSearchResultsVisible {
	return hasSearchInitiated && activeMode;
}

- (id) initWithViewController: (StellarMainTableController *)controller{
	if(self = [super init]) {
		activeMode = NO;
		viewController = controller;
		self.lastResults = [NSArray array];
		hasSearchInitiated = NO;
		resultsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, NAVIGATION_BAR_HEIGHT, 320.0, 380) style: UITableViewStyleGrouped];
		resultsTableView.delegate = self;
		resultsTableView.dataSource = self;
		resultsTableView.backgroundColor = [UIColor whiteColor];
		
		resultsTableView.tableHeaderView = [UITableView ungroupedSectionHeaderWithTitle:@"Search Results"];
		//[resultsTableView applyStandardColors];
		
	}
	return self;
}

- (void) dealloc {
	[lastResults release];
	[super dealloc];
}

#pragma mark UITableViewDataSource methods

- (NSInteger) tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
	return [self.groups count];//[lastResults count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	MultiLineTableViewCell *cell = (MultiLineTableViewCell *)[aTableView dequeueReusableCellWithIdentifier:@"StellarMainSearch"];
	if(cell == nil) {
		cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"StellarMainSearch"] autorelease];
	}
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.selectionStyle = UITableViewCellSelectionStyleGray;

	NSString *key =[[self.groups allKeys] objectAtIndex: indexPath.row];
	cell.textLabel.text =  [[self.groups valueForKey:key] description];
	cell.detailTextLabel.text = [[schoolNameToShortNames valueForKey:key] description];
	cell.detailTextLabel.font = [UIFont fontWithName:STANDARD_FONT size:STANDARD_CONTENT_FONT_SIZE];

	return cell;
}

/*
- (CGFloat) tableView: (UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath {
	return [StellarClassTableCell cellHeightForTableView:tableView class:[self.lastResults objectAtIndex:indexPath.row]];
}*/

- (NSInteger) numberOfSectionsInTableView: (UITableView *)tableView {
	return 1;
}
/*
- (NSString *) tableView: (UITableView *)tableView titleForHeaderInSection: (NSInteger)section {
	if([lastResults count]) {
		return [NSString stringWithFormat:@"%i found", [lastResults count]];
	}
	return nil;
}*/

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	
	if([lastResults count]) {

		return [[[UIView alloc] initWithFrame: CGRectMake(0, 0, 320.0, UNGROUPED_SECTION_HEADER_HEIGHT + 15.0)] autorelease];
	}
	return nil;
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return UNGROUPED_SECTION_HEADER_HEIGHT + 15.0;//UNGROUPED_SECTION_HEADER_HEIGHT;
}

#pragma mark UITableViewDelegate methods

// TODO: this method needs to be rethought;
// currently it leaks an instance of MainSearchGroupdCoursesTableViewController with each execution.
- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
	//viewController.searchController.searchBar.text = @"art and blue";
	
	MainSearchGroupedCoursesTableViewController * vc = [[MainSearchGroupedCoursesTableViewController alloc] initWithViewController:viewController];	
	
	//StellarSearch *s_search = [[StellarSearch alloc] initWithViewController:viewController];
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	[vc setCourseGroupString:cell.detailTextLabel.text];
	[vc setSearchString: viewController.searchController.searchBar.text];

	[StellarModel executeStellarSearch:viewController.searchController.searchBar.text courseGroupName:[[self.groups allKeys] objectAtIndex: indexPath.row] courseName:@"" delegate:vc];

}

#pragma mark ClassesSearchDelegate methods

- (void) searchComplete: (NSArray *)classes searchTerms:searchTerms actualCount:(int) actual_count{
	if([viewController.searchController.searchBar.text isEqualToString:searchTerms]) {
		
		actualCount = actual_count;
		self.lastResults = classes;
		
		self.groups = nil;
		self.groups = [self uniqueCourseGroups];
		
		if ([classes count] > 0) {
			viewController.searchController.searchResultsTableView = resultsTableView;
		
			[viewController.searchController.searchResultsTableView applyStandardCellHeight];
			viewController.searchController.searchResultsTableView.allowsSelection = YES;
			[viewController.searchController.searchResultsTableView reloadData];
			[viewController hideLoadingView];
			[viewController showSearchResultsTable];
		
		
		// if exactly one result found forward user to that result
			if([classes count] == 1) {
				[StellarDetailViewController 
				 launchClass:(StellarClass *)[classes lastObject]
				 viewController: viewController];
			}
		}
		else {
			[viewController hideLoadingView];
			UIAlertView *alert = [[UIAlertView alloc]
								  initWithTitle:NSLocalizedString(@"No Results Found", nil)
								  message:NSLocalizedString(@"Your query returned no matches.", nil)
								  delegate:nil
								  cancelButtonTitle:@"OK" 
								  otherButtonTitles:nil];
			
			[viewController.searchController.searchResultsTableView reloadData];
			
			[alert show];
			[alert release];
		}

	}
}

- (void) handleCouldNotReachStellarWithSearchTerms: (NSString *)searchTerms {
	if([viewController.searchController.searchBar.text isEqualToString:searchTerms]) {
		[viewController hideLoadingView];
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:NSLocalizedString(@"Connection Failed", nil)
							  message:NSLocalizedString(@"Could not connect to server", nil)
							  delegate:nil
							  cancelButtonTitle:@"OK" 
							  otherButtonTitles:nil];
		
		[viewController.searchController.searchResultsTableView reloadData];
		
		[alert show];
		[alert release];
	}
}

- (void) handleTooManySearchResults {
	
	[viewController hideLoadingView];
	UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle:NSLocalizedString(@"Too Many Results", nil)
						  message:NSLocalizedString(@"Retrieved more than 200 results. Please refine your query", nil)
						  delegate:nil
						  cancelButtonTitle:@"OK" 
						  otherButtonTitles:nil];
	
	[viewController.searchController.searchResultsTableView reloadData];
	
	[alert show];
	[alert release];
	
}

- (void) handleTooManySearchResultsForMainSearch: (id)object {
	self.groups = nil;
	self.groups = [self uniqueCourseGroupsForCountDisplayOnly: (id) object];
		
		viewController.searchController.searchResultsTableView = resultsTableView;
		
		[viewController.searchController.searchResultsTableView applyStandardCellHeight];
		viewController.searchController.searchResultsTableView.allowsSelection = YES;
		[viewController.searchController.searchResultsTableView reloadData];
		[viewController hideLoadingView];
		[viewController showSearchResultsTable];

	return;	
	
}


-(NSMutableDictionary *) uniqueCourseGroups{
	//((StellarClass *)[self.lastResults objectAtIndex:indexPath.row]).school;
	schoolNameToShortNames = nil;
	if (schoolNameToShortNames == nil)
		schoolNameToShortNames = [[NSMutableDictionary alloc] init];
	
	NSMutableArray *tempArray = [[[NSMutableArray alloc] init] autorelease];
	NSMutableDictionary *tempDict = [[[NSMutableDictionary alloc] init] autorelease];
	
	for (int index=0; index < [self.lastResults count]; index++) {
		
		if (![tempArray containsObject:((StellarClass *)[self.lastResults objectAtIndex:index]).school]) {
			[tempArray addObject:((StellarClass *)[self.lastResults objectAtIndex:index]).school];
			NSNumber *count = [NSNumber numberWithInt:1];
			
			[tempDict setObject:count forKey:((StellarClass *)[self.lastResults objectAtIndex:index]).school];
			[schoolNameToShortNames setObject:((StellarClass *)[self.lastResults objectAtIndex:index]).school_short 
									   forKey:((StellarClass *)[self.lastResults objectAtIndex:index]).school];
		}
		
		else {
			NSNumber *lastCount = [tempDict objectForKey:((StellarClass *)[self.lastResults objectAtIndex:index]).school];
			
			NSNumber *count = [NSNumber numberWithInt:([lastCount intValue] +1 )];
			[tempDict removeObjectForKey:((StellarClass *)[self.lastResults objectAtIndex:index]).school];
			[tempDict setObject:count forKey:((StellarClass *)[self.lastResults objectAtIndex:index]).school];
		}

		
	}	
	return tempDict;	
}


-(NSMutableDictionary *) uniqueCourseGroupsForCountDisplayOnly:(id) object {
	schoolNameToShortNames = nil;
	if (schoolNameToShortNames == nil)
		schoolNameToShortNames = [[NSMutableDictionary alloc] init];
	
	NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
	
	NSArray *results = (NSArray *) [object objectForKey:@"schools"];
	/*NSString *countString = [[object objectForKey:@"count"] description];
	 int count = [countString intValue];*/
	
	for (int index=0; index < [results count]; index++) {
		
		NSString *schoolName = [[[results objectAtIndex:index] objectForKey:@"name"] description];
		NSString *schoolNameShort = [[[results objectAtIndex:index] objectForKey:@"name_short"] description];
		[tempDict setObject:[[[results objectAtIndex:index] objectForKey:@"count"] description] forKey: schoolName];
		[schoolNameToShortNames setObject:schoolNameShort forKey:schoolName];
	}
	
	return tempDict;		
}

@end
