#import "MapSearchResultsTableView.h"
#import "MapSearchResultAnnotation.h"
#import "MITMapDetailViewController.h"
#import "CampusMapViewController.h"
#import "MITUIConstants.h"

@implementation MapSearchResultsTableView

@synthesize searchResults = _searchResults;
@synthesize isCategory = _isCategory;
@synthesize campusMapVC = _campusMapVC;

- (void)dealloc {
    [super dealloc];
}

- (void)setSearchResults:(NSArray *)searchResults
{
    if (_searchResults != searchResults) {
        [_searchResults release];
        _searchResults = [searchResults retain];
    }
    [self reloadData];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
	// get the annotation for this index
	ArcGISMapAnnotation *annotation = [self.searchResults objectAtIndex:indexPath.row];
	cell.textLabel.text = annotation.name;
	cell.detailTextLabel.text = annotation.street;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	MITMapDetailViewController* detailsVC = [[[MITMapDetailViewController alloc] initWithNibName:@"MITMapDetailViewController"
																						  bundle:nil] autorelease];
	
	ArcGISMapAnnotation *annotation = (ArcGISMapAnnotation *)[self.searchResults objectAtIndex:indexPath.row];
	detailsVC.annotation = annotation;
	detailsVC.title = @"Info";
	detailsVC.campusMapVC = self.campusMapVC;

	if (self.isCategory) {
		detailsVC.queryText = detailsVC.annotation.name;
	} else if(self.campusMapVC.lastSearchText != nil && self.campusMapVC.lastSearchText.length > 0) {
		detailsVC.queryText = self.campusMapVC.lastSearchText;
	}
	
	[self.campusMapVC.navigationController pushViewController:detailsVC animated:YES];
     
}

/*
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	[cell setNeedsLayout];
}
*/

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	return [UITableView ungroupedSectionHeaderWithTitle:
			[NSString stringWithFormat:@"%d found", self.searchResults.count]];
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return UNGROUPED_SECTION_HEADER_HEIGHT;
}

@end

