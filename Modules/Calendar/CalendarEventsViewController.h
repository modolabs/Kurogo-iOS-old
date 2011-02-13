#import <UIKit/UIKit.h>
#import "JSONAPIRequest.h"
#import "CalendarConstants.h"
#import "KGOScrollingTabstrip.h"
#import "KGOSearchDisplayController.h"
#import "KGODatePager.h"
#import "KGOTableViewController.h"

@class DatePickerViewController;
@class KGOScrollingTabstrip;
@class KGOSearchBar;
@class KGODatePager;

@interface CalendarEventsViewController : KGOTableViewController <KGOScrollingTabstripDelegate,
JSONAPIDelegate, KGODatePagerDelegate, KGOSearchDisplayDelegate> {

	CalendarEventListType activeEventList; // today, browse, acad, holidays...
	NSDate *startDate;
	NSDate *endDate;
	NSArray *events;
	
	// views in the body
    UITableView *_eventListTableView;
    UITableView *_eventCategoriesTableView;
    
    NSArray *categories;
	
	// views in the header
    KGOScrollingTabstrip *navScrollView;
    
    KGODatePager *datePicker;
	
	// search
    KGOSearchBar *theSearchBar;
    KGOSearchDisplayController *searchController;
    
	UIView *loadingIndicator;
	
	// category parameter for list of events in a category
	NSInteger theCatID;
	
	BOOL showScroller;
	BOOL dateRangeDidChange;
	
	BOOL categoriesRequestDispatched;
	JSONAPIRequest *apiRequest;
	
}

@property (nonatomic, assign) BOOL showScroller;
@property (nonatomic, assign) BOOL categoriesRequestDispatched;
@property (nonatomic, assign) NSInteger catID;
@property (nonatomic, assign) CalendarEventListType activeEventList;

@property (nonatomic, retain) NSDate *startDate;
@property (nonatomic, retain) NSDate *endDate;
@property (nonatomic, retain) NSArray *events;

@property (nonatomic, retain) NSString *searchTerms;

- (void)makeRequest;

- (void)switchToCategory:(CalendarEventListType)listType;


@end

