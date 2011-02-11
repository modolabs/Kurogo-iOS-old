#import <UIKit/UIKit.h>
#import "JSONAPIRequest.h"
#import "CalendarConstants.h"
#import "EventCategoriesTableView.h"
#import "CalendarMapView.h"
//#import "DatePickerViewController.h"
#import "KGOScrollingTabstrip.h"
#import "KGOSearchDisplayController.h"
#import "KGODatePager.h"

@class EventListTableView;
@class CalendarEventMapAnnotation;
@class DatePickerViewController;
@class KGOScrollingTabstrip;
@class KGOSearchBar;
@class KGODatePager;

@interface CalendarEventsViewController : UIViewController <KGOScrollingTabstripDelegate,
MKMapViewDelegate, JSONAPIDelegate, KGODatePagerDelegate, KGOSearchDisplayDelegate> {

	CalendarEventListType activeEventList; // today, browse, acad, holidays...
	NSDate *startDate;
	NSDate *endDate;
	NSArray *events;
	
	// views in the body
	UITableView *theTableView;
	CalendarMapView *theMapView;
	
	// views in the header
    KGOScrollingTabstrip *navScrollView;
    
    KGODatePager *datePicker;
	
	UIView *nothingFound;
	
	// search
    KGOSearchBar *theSearchBar;
    KGOSearchDisplayController *searchController;
    
	UIView *loadingIndicator;
	
	// category parameter for list of events in a category
	NSInteger theCatID;
	
	BOOL showList;
	BOOL showScroller;
	BOOL dateRangeDidChange;
	
	BOOL requestDispatched;
	BOOL categoriesRequestDispatched;
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

- (void)abortExtraneousRequest;
- (void)makeRequest;

- (void)mapButtonToggled;
- (void)listButtonToggled;

- (void)reloadView:(CalendarEventListType)listType;


@end

