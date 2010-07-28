#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "ShuttleDataManager.h"
#import "CampusMapToolbar.h"
#import "JSONAPIRequest.h"
#import "MITModuleURL.h"
#import "CMModule.h"
#import "TileServerManager.h"
#import "ModoSearchBar.h"

//@class MITMapSearchResultsTable;
@class MITMapSearchResultsVC;
@class MapSelectionController;

@interface CampusMapViewController : UIViewController <UISearchBarDelegate, MKMapViewDelegate,
														JSONAPIDelegate,
														ShuttleDataManagerDelegate, 
														UIAlertViewDelegate>
{

	// the MIT map module in which this view controller is created. 
	CMModule* _campusMapModule;
	
	// our map view controller which renders the map display
	MKMapView* _mapView;
	CampusMapToolbar* _toolBar;
	UIBarButtonItem* _geoButton;
	UIBarButtonItem* _cancelSearchButton;
	UIBarButtonItem* _shuttleButton;

	NSArray* _searchResults;
	BOOL _hasSearchResults;
	NSArray* _filteredSearchResults;
	SEL _searchFilter;
	NSString* _lastSearchText;

	NSArray* _categories;
	UITableView* _categoryTableView;
	
	BOOL _displayShuttles;
	NSMutableArray* _shuttleAnnotations;
	
	// flag indicating whether to display a list of search results or categories. 
	BOOL _displayingList;
	
	// view controller for our search results list display
	MITMapSearchResultsVC* _searchResultsVC;
	
	// bar button to switch view types. 
	UIBarButtonItem* _viewTypeButton;
	
	ModoSearchBar *_searchBar;
	
	// a custom button since we are not using the default bookmark button
	UIButton* _bookmarkButton;
	
	MapSelectionController* _selectionVC;
	
	// these are used for saving state
	MITModuleURL* url;
	
	// Used for storing search results that need to wait on other resources before they are used.
	NSArray *unprocessedSearchResults;
	NSString *unprocessedSearchResultsQuery;
}

@property (nonatomic, retain) UIBarButtonItem* geoButton;
@property (nonatomic, retain) NSArray* searchResults;
@property (nonatomic, assign) CMModule* campusMapModule;

@property (readonly) MKMapView* mapView;
@property (nonatomic, retain) NSString* lastSearchText;
@property BOOL hasSearchResults;
@property (readonly) BOOL displayingList;
@property (readonly) ModoSearchBar* searchBar;
@property (readonly) MITModuleURL* url;
@property (nonatomic, retain) NSArray *unprocessedSearchResults;
@property (nonatomic, retain) NSString *unprocessedSearchResultsQuery;

// execute a search
-(void) search:(NSString*)searchText;

// this is called in handleLocalPath: query: and also by setSearchResults:
-(void) setSearchResultsWithoutRecentering:(NSArray*)searchResults;

-(void) setSearchResults:(NSArray *)searchResults;

// set the search results with a filter. Filter will be the unique category for
// each of the search results. So if each building should be unique, filter can be bldgnum
-(void) setSearchResults:(NSArray *)searchResults withFilter:(SEL)filter;

// show the list view. If false, hides the list view so the map is displayed. 
-(void) showListView:(BOOL)showList;

// push an annotations detail page onto the stack
-(void) pushAnnotationDetails:(id <MKAnnotation>) annotation animated:(BOOL)animated;

@end
