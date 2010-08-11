#import "StellarSearch.h"
#import "StellarClass.h"
#import "StellarDetailViewController.h"
#import "StellarMainTableController.h"
#import "StellarClassTableCell.h"
#import "UITableView+MITUIAdditions.h"
#import "MITUIConstants.h"
#import "MITSearchDisplayController.h"

@implementation StellarSearch

@synthesize lastResults;
@synthesize activeMode;

- (BOOL) isSearchResultsVisible {
	return hasSearchInitiated && activeMode;
}
	
- (id) initWithViewController: (StellarMainTableController *)controller{
	if(self = [super init]) {
		activeMode = NO;
		viewController = controller;
		self.lastResults = [NSArray array];
		hasSearchInitiated = NO;
	}
	return self;
}

- (void) dealloc {
	[lastResults release];
	[super dealloc];
}

#pragma mark UITableViewDataSource methods

- (NSInteger) tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
	return [lastResults count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:@"StellarSearch"];
	if(cell == nil) {
		cell = [[[StellarClassTableCell alloc] initWithReusableCellIdentifier:@"StellarSearch"] autorelease];
	}

	StellarClass *stellarClass = [self.lastResults objectAtIndex:indexPath.row];
	[StellarClassTableCell configureCell:cell withStellarClass:stellarClass];
	return cell;
}

- (CGFloat) tableView: (UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath {
	return [StellarClassTableCell cellHeightForTableView:tableView class:[self.lastResults objectAtIndex:indexPath.row]];
}
			
- (NSInteger) numberOfSectionsInTableView: (UITableView *)tableView {
	return 1;
}

- (NSString *) tableView: (UITableView *)tableView titleForHeaderInSection: (NSInteger)section {
	if([lastResults count]) {
		return [NSString stringWithFormat:@"%i found", [lastResults count]];
	}
	return nil;
}

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString *headerTitle = nil;
	
	if([lastResults count]) {
		headerTitle = [NSString stringWithFormat:@"%i found", [lastResults count]];
		return [UITableView ungroupedSectionHeaderWithTitle:headerTitle];
	}
	return nil;
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return UNGROUPED_SECTION_HEADER_HEIGHT;
}

#pragma mark UITableViewDelegate methods

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	[StellarDetailViewController 
		launchClass:(StellarClass *)[self.lastResults objectAtIndex:indexPath.row]
		viewController:viewController];
}

#pragma mark ClassesSearchDelegate methods

- (void) searchComplete: (NSArray *)classes searchTerms:searchTerms {
	if([viewController.searchController.searchBar.text isEqualToString:searchTerms]) {
		self.lastResults = classes;
		
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
}

- (void) handleCouldNotReachStellarWithSearchTerms: (NSString *)searchTerms {
	if([viewController.searchController.searchBar.text isEqualToString:searchTerms]) {
		[viewController hideLoadingView];
		UIAlertView *alert = [[UIAlertView alloc]
			initWithTitle:@"Connection Failed" 
			message:@"Could not connect to Stellar to execute search, please try again later."
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
						  initWithTitle:@"Narrow Search" 
						  message:@"Retrieved more than 100 results. Please refine your query"
						  delegate:nil
						  cancelButtonTitle:@"OK" 
						  otherButtonTitles:nil];
	
	[viewController.searchController.searchResultsTableView reloadData];
	
	[alert show];
	[alert release];
}

@end
