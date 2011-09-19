#import <UIKit/UIKit.h>
#import "KGOSearchModel.h"
#import "KGOSearchBar.h"
#import "KGOTableViewController.h"
#import "KGODetailPager.h"

@class KGOSearchDisplayController;
@protocol KGOSearchResult;


@protocol KGOSearchResultsDelegate <NSObject>

- (void)resultsHolder:(id<KGOSearchResultsHolder>)resultsHolder didSelectResult:(id<KGOSearchResult>)aResult;

@end


@protocol KGOSearchDisplayDelegate <KGOSearchResultsDelegate>

- (BOOL)searchControllerShouldShowSuggestions:(KGOSearchDisplayController *)controller; // whether or not to show recent searches
- (NSArray *)searchControllerValidModules:(KGOSearchDisplayController *)controller; // modules to pass the search term to
- (NSString *)searchControllerModuleTag:(KGOSearchDisplayController *)controller; // module tag to associate with saved search term

@optional

- (void)searchController:(KGOSearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView;
- (void)searchController:(KGOSearchDisplayController *)controller willReloadSearchResultsTableView:(UITableView *)tableView;
- (void)searchController:(KGOSearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView;
- (BOOL)searchControllerShouldLinkToMap:(KGOSearchDisplayController *)controller;

@end


@class KGOTableController;

@interface KGOSearchDisplayController : NSObject <KGOSearchBarDelegate, KGOTableViewDataSource, KGOSearchResultsHolder, KGODetailPagerController> {
    
    id<KGOSearchDisplayDelegate> _delegate;
    //NSArray *_searchResults;
    BOOL _showingOnlySearchResults;

    KGOSearchBar *_searchBar;
    BOOL _active;
    UIViewController *_searchContentsController;
    KGOTableController *_searchTableController;
    UIControl *_searchOverlay;
    BOOL _showingMapView;
}

@property (nonatomic) BOOL showsSearchOverlay;

@property (nonatomic, readonly) BOOL showingOnlySearchResults; // NO if tableview includes search suggestions
@property (nonatomic, readonly) id<KGOSearchDisplayDelegate> delegate;

//@property (nonatomic, retain) NSArray *searchResults;
@property (nonatomic, readonly) NSArray *searchResults;

@property (nonatomic, retain) NSMutableDictionary *multiSearchResults;
@property (nonatomic, retain) NSMutableArray *searchSources;

@property (nonatomic, readonly) KGOSearchBar *searchBar;
@property (nonatomic, getter=isActive) BOOL active;
@property (nonatomic, readonly) UIViewController *searchContentsController;
@property (nonatomic, readonly) KGOTableController *searchTableController;

@property (nonatomic) NSUInteger maxResultsPerSection;

- (id)initWithSearchBar:(KGOSearchBar *)searchBar
               delegate:(id<KGOSearchDisplayDelegate>)delegate
     contentsController:(UIViewController *)viewController;

- (void)setActive:(BOOL)visible animated:(BOOL)animated;
- (void)executeSearch:(NSString *)text params:(NSDictionary *)params;

- (void)focusSearchBarAnimated:(BOOL)animated;
- (void)unfocusSearchBarAnimated:(BOOL)animated;

- (void)showSearchOverlayAnimated:(BOOL)animated;
- (void)hideSearchOverlayAnimated:(BOOL)animated;

- (void)showSearchResultsTableView;
- (void)hideSearchResultsTableView;

- (void)reloadSearchResultsTableView;

- (BOOL)canShowMapView; // whether there are mappable results to link to map module
//- (NewsStory *)storyWithDictionary:(NSDictionary *)storyDict;

@end
