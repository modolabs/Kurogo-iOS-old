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

    // calendars are organized in groups.
    // groupTitles is all the top level groups.
    // if there are multiple groups, their titles are shown in the tab strip.
    NSMutableArray *_groupTitles;

    // at any given time the user can only view the contents of one group.
    // if there are multiple groups, the group being viewed will be pressed in the tab strip.
    NSInteger _currentGroupIndex;

    // currentCalendars is the list of calendars associated with the current group.
    // if there is only one group, the calendar titles appear in the tab strip.
    NSArray *_currentCalendars;
    
    // if the tab strip is showing calendar titles, this is the currently selected calendar
    KGOCalendar *_currentCalendar;
    
    // the table will either be a plain, possibly sectioned list of events
    // or a grouped, unsectioned list of categories.
    NSArray *_currentSections;
    NSDictionary *_currentEventsBySection;
}

@property(nonatomic, retain) ModuleTag *moduleTag;
@property(nonatomic, retain) CalendarDataManager *dataManager;
@property(nonatomic, retain) KGOCalendar *currentCalendar;

// temporarily set by federated search
@property(nonatomic, retain) NSString *federatedSearchTerms;
@property(nonatomic, retain) NSArray *federatedSearchResults;

@property(nonatomic, retain) NSMutableArray *groupTitles;
@property(nonatomic, retain) NSArray *currentSections;
@property(nonatomic, retain) NSDictionary *currentEventsBySection;

@property(nonatomic) BOOL showsGroups;
@property(nonatomic) BOOL eventsLoaded;

- (void)clearEvents;
- (void)clearCalendars;
- (void)setupTabstripButtons;

@end
