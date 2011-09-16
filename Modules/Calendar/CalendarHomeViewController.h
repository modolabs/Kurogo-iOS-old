#import "KGOTableViewController.h"
#import "KGODatePager.h"
#import "KGOScrollingTabstrip.h"
#import "CalendarDataManager.h"
#import "KGOSearchBar.h"
#import "KGOSearchDisplayController.h"

bool isOverOneMonth(NSTimeInterval interval);
bool isOverOneDay(NSTimeInterval interval);
bool isOverOneHour(NSTimeInterval interval);

@interface CalendarHomeViewController : KGOTableViewController <KGODatePagerDelegate,
KGOScrollingTabstripSearchDelegate, CalendarDataManagerDelegate> {
    
    IBOutlet KGODatePager *_datePager;
    IBOutlet KGOScrollingTabstrip *_tabstrip;
    IBOutlet UIActivityIndicatorView *_loadingView;
    
    NSMutableArray *_groupTitles;
    NSInteger _currentGroupIndex;

    KGOCalendar *_currentCalendar;
    
    // the table will either be a plain, possibly sectioned list of events
    // or a grouped, unsectioned list of categories.
    NSArray *_currentSections;
    NSDictionary *_currentEventsBySection;

    NSArray *_currentCategories;
}

@property(nonatomic, retain) NSString *moduleTag;
@property(nonatomic, retain) CalendarDataManager *dataManager;
@property(nonatomic, retain) NSString *searchTerms;
@property(nonatomic, retain) KGOCalendar *currentCalendar;

@property(nonatomic, retain) NSMutableArray *groupTitles;
@property(nonatomic, retain) NSArray *currentSections;
@property(nonatomic, retain) NSDictionary *currentEventsBySection;

@property(nonatomic) BOOL showsGroups;

- (void)clearEvents;
- (void)clearCalendars;
- (void)setupTabstripButtons;

@end
