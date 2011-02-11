#import <UIKit/UIKit.h>
#import "JSONAPIRequest.h"
#import "CalendarConstants.h"
#import "EventCategoriesTableView.h"
#import "CalendarMapView.h"
//#import "DatePickerViewController.h"
#import "NavScrollerView.h"
#import "KGOSearchDisplayController.h"
#import "KGODatePager.h"

@class EventListTableView;
@class CalendarEventMapAnnotation;
@class DatePickerViewController;
@class NavScrollerView;
@class KGOSearchBar;
@class KGODatePager;

@interface CalendarEventsViewController : UIViewController <NavScrollerDelegate,
MKMapViewDelegate, JSONAPIDelegate, KGODatePagerDelegate, KGOSearchDisplayDelegate> {

	CalendarEventListType activeEventList; // today, browse, acad, holidays...
	NSDate *startDate;
	NSDate *endDate;
	NSArray *events;
	
	// views in the body
	UITableView *theTableView;
	CalendarMapView *theMapView;
	
	// views in the header
    NavScrollerView *navScrollView;
    
    KGODatePager *datePicker;
	
	UIView *nothingFound;
	
	// search
    KGOSearchBar *theSearchBar;
    KGOSearchDisplayController *searchController;
    
	UIView *loadingIndicator;
	// this is a tableview subclass but we're only using it for
	// its delegate methods
	//EventListTableView *searchResultsTableView;
	//CalendarMapView *searchResultsMapView;
	
	// category parameter for list of events in a category
	NSInteger theCatID;
	
	BOOL showList;
	BOOL showScroller;
	BOOL dateRangeDidChange;
	
	BOOL requestDispatched;
	BOOL categoriesRequestDispatched;
    //BOOL isFederatedSearch;
	JSONAPIRequest *apiRequest;
	
}

@property (nonatomic, assign) BOOL showScroller;
@property (nonatomic, assign) BOOL showList;
@property (nonatomic, assign) BOOL categoriesRequestDispatched;
@property (nonatomic, assign) NSInteger catID;
@property (nonatomic, assign) CalendarEventListType activeEventList;

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) MKMapView *mapView;

@property (nonatomic, retain) NSDate *startDate;
@property (nonatomic, retain) NSDate *endDate;
@property (nonatomic, retain) NSArray *events;

@property (nonatomic, retain) NSString *searchTerms;

//@property (nonatomic, retain) DatePickerViewController *dateSelector;

- (void)abortExtraneousRequest;
- (void)makeRequest;
//- (void)makeSearchRequest:(NSString *)searchTerms;
//- (void)presentSearchResults:(NSArray *)results searchText:(NSString *)searchText searchSpan:(NSString *)searchSpan;

- (void)mapButtonToggled;
- (void)listButtonToggled;
//- (void)sideButtonPressed:(id)sender;
- (void)buttonPressed:(id)sender;

- (void)reloadView:(CalendarEventListType)listType;
- (void)selectScrollerButton:(NSString *)buttonTitle;


@end

