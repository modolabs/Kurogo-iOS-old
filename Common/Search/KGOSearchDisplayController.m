#import "KGOSearchDisplayController.h"
#import "KGOTheme.h"
#import "KGOAppDelegate.h"
#import "KGOModule.h"
#import "KGOTableViewController.h"
#import "KGOSearchModel.h"
#import "CoreDataManager.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "RecentSearch.h"
#import <MapKit/MKAnnotation.h>

#define MAX_SEARCH_RESULTS 25


static NSString * RecentSearchesEntityName = @"RecentSearch";


@interface KGOSearchDisplayController (Private)

- (void)searchOverlayTapped;
- (void)releaseSearchOverlay;

@end



@implementation KGOSearchDisplayController

@synthesize searchBar = _searchBar, active = _active, delegate = _delegate,
searchContentsController = _searchContentsController,
searchTableController = _searchTableController,
searchResults = _searchResults,
showingOnlySearchResults = _showingOnlySearchResults, showsSearchOverlay;


- (id)initWithSearchBar:(KGOSearchBar *)searchBar
               delegate:(id<KGOSearchDisplayDelegate>)delegate
     contentsController:(UIViewController *)viewController
{
    self = [super init];
    if (self) {
        self.showsSearchOverlay = YES;
        
        _searchBar = [searchBar retain];
        _searchBar.delegate = self;
        
        _delegate = delegate;
        
        _searchContentsController = viewController;

        // UI Automation testing
		_searchBar.isAccessibilityElement = YES; // Make search bar available to automation and accessibility features.
		_searchBar.accessibilityLabel = [NSString stringWithFormat:@"%@ %@", viewController.title, @"Search Bar"];
    }
    return self;
}


- (void)dealloc {
    [_searchTableController release];
    _searchTableController = nil;
    
    [self releaseSearchOverlay];
    
    [_searchBar release];
    _searchBar = nil;
    
    _searchContentsController = nil;
    _delegate = nil;
    
    [super dealloc];
}

- (void)executeSearch:(NSString *)text params:(NSDictionary *)params {
	_searchBar.text = text;
    NSArray *moduleTags = [self.delegate searchControllerValidModules:self];
    for (NSString *moduleTag in moduleTags) {
        KGOModule *module = [KGO_SHARED_APP_DELEGATE() moduleForTag:moduleTag];
        if ([module supportsFederatedSearch]) { // TODO: use a less strict check
            [module performSearchWithText:text params:params delegate:self];
        }
    }
}

#pragma mark Search UI

- (void)showSearchResultsTableView {
    if (!_searchTableController) {
        _searchTableController = [[KGOTableController alloc] initWithSearchController:self];
    }
    
    if (![_searchTableController topTableView]) {
        CGRect frame = CGRectMake(0.0, _searchBar.frame.size.height, _searchContentsController.view.frame.size.width,
                                  _searchContentsController.view.frame.size.height - _searchBar.frame.size.height);
        
        [_searchTableController addTableViewWithFrame:frame style:UITableViewStylePlain dataSource:self];
        _searchTableController.caching = ![self.delegate searchControllerShouldShowSuggestions:self];
    }
    
    UITableView *tableView = [_searchTableController topTableView];
    [_searchContentsController.view bringSubviewToFront:tableView];
    
    if ([self.delegate respondsToSelector:@selector(searchController:didShowSearchResultsTableView:)]) {
        [self.delegate searchController:self didShowSearchResultsTableView:tableView];
    }
}

- (void)hideSearchResultsTableView {
    UITableView *tableView = [_searchTableController topTableView];
    if ([self.delegate respondsToSelector:@selector(searchController:willHideSearchResultsTableView:)]) {
        [self.delegate searchController:self willHideSearchResultsTableView:tableView];
    }
    if (_searchTableController) {
        [_searchTableController removeTableView:tableView];
    }
}

- (void)reloadSearchResultsTableView {
    UITableView *tableView = [_searchTableController topTableView];
	if ([self.delegate respondsToSelector:@selector(searchController:willReloadSearchResultsTableView:)]) {
		[self.delegate searchController:self willReloadSearchResultsTableView:tableView];
	}
	[_searchTableController reloadDataForTableView:tableView];
}

- (void)focusSearchBarAnimated:(BOOL)animated {
    [_searchBar setShowsCancelButton:YES animated:animated];
    [_searchBar becomeFirstResponder];
}

- (void)unfocusSearchBarAnimated:(BOOL)animated {
    [_searchBar setShowsCancelButton:NO animated:animated];
    [_searchBar resignFirstResponder];
}

- (void)showSearchOverlayAnimated:(BOOL)animated {
    if (!self.showsSearchOverlay) {
        return;
    }
    
    if (!_searchOverlay) {
        CGFloat yOrigin = _searchBar.frame.origin.y + _searchBar.frame.size.height;
        CGSize containerSize = _searchContentsController.view.frame.size;
        CGRect frame = CGRectMake(0.0, yOrigin, containerSize.width, containerSize.height - yOrigin);

        _searchOverlay = [[UIControl alloc] initWithFrame:frame];
        _searchOverlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
        _searchOverlay.alpha = 0.0;

        [_searchOverlay addTarget:self action:@selector(searchOverlayTapped) forControlEvents:UIControlEventTouchDown];
    }

    [_searchContentsController.view addSubview:_searchOverlay];
    
    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.4];
        _searchOverlay.alpha = 1.0;
        [UIView commitAnimations];
    } else {
        _searchOverlay.alpha = 1.0;
    }
}

- (void)hideSearchOverlayAnimated:(BOOL)animated {
    if (_searchOverlay) {
        if (animated) {
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.4];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(releaseSearchOverlay)];
            _searchOverlay.alpha = 0.0;
            [UIView commitAnimations];
        } else {
            [self releaseSearchOverlay];
        }
    }
}

- (void)releaseSearchOverlay {
    if (_searchOverlay) {
        [_searchOverlay removeFromSuperview];
        [_searchOverlay release];
        _searchOverlay = nil;
    }
}

- (void)searchOverlayTapped {
    [self setActive:NO animated:YES];
}

- (void)setActive:(BOOL)visible animated:(BOOL)animated {
    _active = visible;
    
    if (_active) {
        [self focusSearchBarAnimated:animated];
        [self showSearchOverlayAnimated:animated];
    } else {
        [self unfocusSearchBarAnimated:animated];
        [self hideSearchOverlayAnimated:animated];
    }
}


- (BOOL)canShowMapView {
    if (self.searchResults.count) {
        for (id<KGOSearchResult> aResult in self.searchResults) {
            if ([aResult conformsToProtocol:@protocol(MKAnnotation)]) {
                id<MKAnnotation>annotation = (id<MKAnnotation>)aResult;
                if (annotation.coordinate.latitude && annotation.coordinate.longitude) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

#pragma mark KGOSearchBarDelegate

- (void)toolbarItemTapped:(UIBarButtonItem *)item {
    if ([item.title isEqualToString:NSLocalizedString(@"Map", nil)]) {
        NSDictionary *params = [NSDictionary dictionaryWithObject:self.searchResults forKey:@"searchResults"];
        [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameSearch forModuleTag:MapTag params:params];
    }
}

#pragma mark KGOSearchBarDelegate

- (void)searchBarTextDidBeginEditing:(KGOSearchBar *)searchBar {
    [self setActive:YES animated:YES];
}

- (void)searchBarSearchButtonClicked:(KGOSearchBar *)searchBar {
    [self unfocusSearchBarAnimated:YES];
    [self executeSearch:searchBar.text params:nil];
    
    self.searchResults = [NSArray array];
    [self reloadSearchResultsTableView];

    // save search term to recent searches
    NSString *moduleTag = [self.delegate searchControllerModuleTag:self];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"text = %@ AND module = %@", searchBar.text, moduleTag];
    DLog(@"%@", [pred description]);
    RecentSearch *recentSearch = [[[CoreDataManager sharedManager] objectsForEntity:RecentSearchesEntityName matchingPredicate:pred] lastObject];
    if (!recentSearch) {
        recentSearch = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:RecentSearchesEntityName];
        recentSearch.module = moduleTag;
        recentSearch.text = searchBar.text;
    }
    recentSearch.date = [NSDate date];
    [[CoreDataManager sharedManager] saveData];
}

- (void)searchBarCancelButtonClicked:(KGOSearchBar *)searchBar {
	_showingOnlySearchResults = NO;
    [self hideSearchResultsTableView];
    [self setActive:NO animated:YES];
    _searchBar.text = nil;
}

- (void)searchBarBookmarkButtonClicked:(KGOSearchBar *)searchBar {

}

- (void)searchBar:(KGOSearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (!_showingOnlySearchResults && [self.delegate searchControllerShouldShowSuggestions:self]) {
		if ([searchText length]) {
			NSMutableArray *searchResults = [NSMutableArray array];
			
			// fetch recent searches
			NSMutableArray *recentsParams = [NSMutableArray arrayWithObject:searchText];
			NSMutableString *recentsQuery = [NSMutableString stringWithString:@"text BEGINSWITH %@"];
			NSMutableString *orClause = [NSMutableString string];
			
			// passing nil as the result to this delegate method will invoke search on all modules
			NSArray *moduleTags = [self.delegate searchControllerValidModules:self];
			for (NSString *moduleTag in moduleTags) {
				if ([orClause length]) {
					[orClause appendString:@" OR module = %@"];
				} else {
					[orClause appendString:@"module = %@"];
				}
				[recentsParams addObject:moduleTag];
				
				KGOModule *module = [KGO_SHARED_APP_DELEGATE() moduleForTag:moduleTag];
				if ([module supportsFederatedSearch]) { // TODO: use a less strict check
					[searchResults addObjectsFromArray:[module cachedResultsForSearchText:searchText params:nil]];
				}
			}
			
			if ([orClause length]) {
				[recentsQuery appendString:[NSString stringWithFormat:@" AND (%@)", orClause]];
			}
			
			NSPredicate *pred = [NSPredicate predicateWithFormat:recentsQuery argumentArray:recentsParams];
			DLog(@"%@", [pred description]);
			
			NSArray *recents = [[CoreDataManager sharedManager] objectsForEntity:RecentSearchesEntityName matchingPredicate:pred];
			self.searchResults = [recents arrayByAddingObjectsFromArray:searchResults];
			
		} else {
			self.searchResults = nil;
		}
        
        if (self.searchResults.count) {
            [self showSearchResultsTableView];
            [self reloadSearchResultsTableView];
        } else {
			[self hideSearchResultsTableView];
		}
    }
}

- (void)searchBar:(KGOSearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {

}

#pragma mark KGOSearchResultsHolder

- (void)searcher:(id)searcher didReceiveResults:(NSArray *)results {
    if (!_showingOnlySearchResults) {
        _showingOnlySearchResults = YES;
        self.searchResults = results;
    } else {
        self.searchResults = [self.searchResults arrayByAddingObjectsFromArray:results];
    }
    [self showSearchResultsTableView];
    [self reloadSearchResultsTableView];
    if ((![self.delegate respondsToSelector:@selector(searchControllerShouldLinkToMap:)] // turn on map by default if available
		 || [self.delegate searchControllerShouldLinkToMap:self])
		&& [self canShowMapView])
	{
        if (!_searchBar.toolbarItems.count) {
            [_searchBar addToolbarButtonWithTitle:NSLocalizedString(@"Map", nil)];
        }
        [_searchBar showToolbarAnimated:YES];
    }
}

#pragma mark KGOTableDataSource

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id<KGOSearchResult> result = [self.searchResults objectAtIndex:indexPath.row];
    if ([result isKindOfClass:[RecentSearch class]]) {
        RecentSearch *recentSearch = (RecentSearch *)result;
        [self unfocusSearchBarAnimated:YES];
        [self executeSearch:recentSearch.text params:nil];
    } else {
        [self.delegate resultsHolder:self didSelectResult:result];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSArray *)tableView:(UITableView *)tableView viewsForCellAtIndexPath:(NSIndexPath *)indexPath {
    id<KGOSearchResult> result = [self.searchResults objectAtIndex:indexPath.row];
    if ([result respondsToSelector:@selector(viewsForTableCell)]) {
        return [result viewsForTableCell];
    }
    return nil;
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath {
    id<KGOSearchResult> result = [self.searchResults objectAtIndex:indexPath.row];
    if (![result respondsToSelector:@selector(viewsForTableCell)] || ![result viewsForTableCell]) {
        NSString *title = [result title];
        NSString *subtitle = [result respondsToSelector:@selector(subtitle)] ? [result subtitle] : nil;
        
        // TODO: have the objects decide this
        NSString *accessoryType = [result isKindOfClass:[RecentSearch class]] ? nil : KGOAccessoryTypeChevron;
        
        return [[^(UITableViewCell *cell) {
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.textLabel.text = title;
            cell.detailTextLabel.text = subtitle;
            cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:accessoryType];
        } copy] autorelease];
    }
    
    return nil;
}

- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath {
    return KGOTableCellStyleSubtitle;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (_showingOnlySearchResults) {
        return [NSString stringWithFormat:@"%d results", self.searchResults.count];
    }
    return nil;
}

// TODO: uncomment and edit if we have search results that need multiple sections
/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
*/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [_searchTableController tableView:tableView cellForRowAtIndexPath:indexPath];
}

#pragma mark KGODetailPagerController

- (NSInteger)numberOfSections:(KGODetailPager *)pager {
    return 1;
}

- (NSInteger)pager:(KGODetailPager *)pager numberOfPagesInSection:(NSInteger)section {
    return self.searchResults.count;
}

- (id<KGOSearchResult>)pager:(KGODetailPager *)pager contentForPageAtIndexPath:(NSIndexPath *)indexPath {
    return [self.searchResults objectAtIndex:indexPath.row];
}

@end
