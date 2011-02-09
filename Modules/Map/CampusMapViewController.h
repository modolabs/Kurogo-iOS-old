#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "JSONAPIRequest.h"
#import "MapModule.h"
#import "KGOSearchBar.h"
#import "KGOTableViewController.h"
#import "KGOSearchDisplayController.h"

@class MapSearchResultsTableView;
@class MapSelectionController;
@class CampusMapToolbar;

@interface CampusMapViewController : KGOTableViewController <UISearchBarDelegate, MKMapViewDelegate, JSONAPIDelegate, UIAlertViewDelegate, KGOSearchDisplayDelegate>
{

	// the MIT map module in which this view controller is created. 
	MapModule* _campusMapModule;
	
	// our map view controller which renders the map display
	MKMapView* _mapView;
	CampusMapToolbar* _toolBar;
	UIBarButtonItem* _cancelSearchButton;

    // user location
    UIBarButtonItem* _geoButton;
    CLLocationCoordinate2D _lastUserLocation;
    
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
	KGOSearchBar *_searchBar;
    KGOSearchDisplayController *_searchController;
	MapSearchResultsTableView *_searchResultsTableView;	
	
	// a custom button since we are not using the default bookmark button
	UIButton* _bookmarkButton;
	
	MapSelectionController *_selectionVC;
}

@property (nonatomic, retain) UIBarButtonItem *geoButton;
@property (nonatomic, retain) NSArray *searchResults;
@property (nonatomic, assign) MapModule *campusMapModule;
@property (nonatomic, retain) MapSearchResultsTableView *searchResultsTableView;
@property (nonatomic, retain) KGOSearchDisplayController *searchController;
@property (readonly) MKMapView *mapView;
@property (nonatomic, retain) NSString *lastSearchText;
@property BOOL hasSearchResults;
@property (readonly) BOOL displayingList;
@property (readonly) KGOSearchBar *searchBar;

// execute a search
- (void)search:(NSString *)searchText params:(NSDictionary *)params;

// this is called in handleLocalPath: query: and also by setSearchResults:
- (void)setSearchResultsWithoutRecentering:(NSArray *)searchResults;
- (void)setSearchResults:(NSArray *)searchResults withFilter:(SEL)filter; // filter is unique category for each search result, e.g. bldgnum
- (void)showListView:(BOOL)showList;                                      // if showList is true, show list view; otherwise show map view
- (void)pushAnnotationDetails:(id <MKAnnotation>) annotation animated:(BOOL)animated;

@end
