#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "JSONAPIRequest.h"
#import "CMModule.h"
#import "ModoSearchBar.h"

@class MapSearchResultsTableView;
@class MapSelectionController;
@class MITSearchDisplayController;
@class CampusMapToolbar;

@interface CampusMapViewController : UIViewController <UISearchBarDelegate, MKMapViewDelegate,
														JSONAPIDelegate, UIAlertViewDelegate>
{

	// the MIT map module in which this view controller is created. 
	CMModule* _campusMapModule;
	
	// our map view controller which renders the map display
	MKMapView* _mapView;
	CampusMapToolbar* _toolBar;
	UIBarButtonItem* _geoButton;
	UIBarButtonItem* _cancelSearchButton;

	NSArray *_searchResults;
	BOOL _hasSearchResults;
	NSArray* _filteredSearchResults;
	SEL _searchFilter;
	NSString* _lastSearchText;

	NSArray* _categories;
	UITableView* _categoryTableView;
	
	// flag indicating whether to display a list of search results or categories. 
	BOOL _displayingList;

	// bar button to switch view types. 
	UIBarButtonItem* _viewTypeButton;
	
    // search UI
	ModoSearchBar *_searchBar;
    MITSearchDisplayController *_searchController;
	MapSearchResultsTableView *_searchResultsTableView;	
	
	// a custom button since we are not using the default bookmark button
	UIButton* _bookmarkButton;
	
	MapSelectionController *_selectionVC;
}

@property (nonatomic, retain) UIBarButtonItem *geoButton;
@property (nonatomic, retain) NSArray *searchResults;
@property (nonatomic, assign) CMModule *campusMapModule;
@property (nonatomic, retain) MapSearchResultsTableView *searchResultsTableView;
@property (nonatomic, retain) MITSearchDisplayController *searchController;
@property (readonly) MKMapView *mapView;
@property (nonatomic, retain) NSString *lastSearchText;
@property BOOL hasSearchResults;
@property (readonly) BOOL displayingList;
@property (readonly) ModoSearchBar *searchBar;

// execute a search
- (void)search:(NSString *)searchText params:(NSDictionary *)params;

// this is called in handleLocalPath: query: and also by setSearchResults:
- (void)setSearchResultsWithoutRecentering:(NSArray *)searchResults;
- (void)setSearchResults:(NSArray *)searchResults withFilter:(SEL)filter; // filter is unique category for each search result, e.g. bldgnum
- (void)showListView:(BOOL)showList;                                      // if showList is true, show list view; otherwise show map view
- (void)pushAnnotationDetails:(id <MKAnnotation>) annotation animated:(BOOL)animated;

@end
