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
		actualCount = 0;
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
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}

	StellarClass *stellarClass = [self.lastResults objectAtIndex:indexPath.row];
	StellarClass *stellarPreviousClass;
	StellarClass *stellarNextClass;
	
	if (indexPath.row > 0) {
		
		// Some logic to ensure that either the pevious or the next class is passed to the configurCell function
		stellarPreviousClass = [self.lastResults objectAtIndex:indexPath.row - 1];
		
		if ([self.lastResults count] > indexPath.row + 1) 
			stellarNextClass = [self.lastResults objectAtIndex:indexPath.row + 1];
		
		else
			stellarNextClass = stellarPreviousClass;
		
		if (![stellarPreviousClass.name isEqualToString:stellarClass.name])
			stellarPreviousClass = stellarNextClass;
		
	}
	else {
		if ([self.lastResults count] > 1)
			stellarPreviousClass = [self.lastResults objectAtIndex:indexPath.row + 1];
		
		else 
			stellarPreviousClass = nil;
	}
	
	
	[StellarClassTableCell configureCell:cell withStellarClass:stellarClass previousClassInList:stellarPreviousClass];
	return cell;
}

- (CGFloat) tableView: (UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath {
	//return [StellarClassTableCell cellHeightForTableView:tableView class:[self.lastResults objectAtIndex:indexPath.row]];

	StellarClass *stellarClass = [self.lastResults objectAtIndex:indexPath.row];
	StellarClass *stellarPreviousClass;
	StellarClass *stellarNextClass;
	
	if (indexPath.row > 0) {
		
		// Some logic to ensure that either the pevious or the next class is passed to the configurCell function
		stellarPreviousClass = [self.lastResults objectAtIndex:indexPath.row - 1];
		
		if ([self.lastResults count] > indexPath.row + 1) 
			stellarNextClass = [self.lastResults objectAtIndex:indexPath.row + 1];
		
		else
			stellarNextClass = stellarPreviousClass;
		
		if (![stellarPreviousClass.name isEqualToString:stellarClass.name])
			stellarPreviousClass = stellarNextClass;
		
	}
	else {
		if ([self.lastResults count] > 1)
			stellarPreviousClass = [self.lastResults objectAtIndex:indexPath.row + 1];
		
		else 
			stellarPreviousClass = nil;
	}
	
	NSString *detail = [StellarClassTableCell setStaffNames:stellarClass previousClassInList:stellarPreviousClass];
	return [StellarClassTableCell cellHeightForTableView:tableView class:stellarClass detailString:detail];
}
			
- (NSInteger) numberOfSectionsInTableView: (UITableView *)tableView {
	return 1;
}

- (NSString *) tableView: (UITableView *)tableView titleForHeaderInSection: (NSInteger)section {
	if([lastResults count]) {
		if (actualCount > [lastResults count])
			return [NSString stringWithFormat:@"Displaying %i of many", [lastResults count]];
		
		return [NSString stringWithFormat:@"%i found in %@", [lastResults count], viewController.navigationItem.title];
	}
	return nil;
}

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString *headerTitle = nil;
	
	if([lastResults count]) {
		if (actualCount > [lastResults count])
			headerTitle =  [NSString stringWithFormat:@"Displaying %i of many", [lastResults count]];
		else
			headerTitle = [NSString stringWithFormat:@"%i found in %@", [lastResults count], viewController.navigationItem.title];
		
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

- (void) searchComplete: (NSArray *)classes searchTerms:searchTerms actualCount:(int) actual_count{
	if([viewController.searchController.searchBar.text isEqualToString:searchTerms]) {
		
		actualCount = actual_count;
		self.lastResults = classes;
		
		if ([self.lastResults count] > 0) {
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
			message:NSLocalizedString(@"Could not retrieve results, please try again later.", nil)
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

/* Just to make the compiler happy */
-(void)handleTooManySearchResultsForMainSearch:(id)object {
}

@end
