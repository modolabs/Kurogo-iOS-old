#import <UIKit/UIKit.h>
#import "KGODetailPager.h"

@class KGOEventWrapper, EventDetailTableView, CalendarDataManager;

@interface CalendarDetailViewController : UIViewController <KGODetailPagerController, KGODetailPagerDelegate> {
    
    EventDetailTableView *_tableView;
    KGOEventWrapper *_event;
}

@property (nonatomic, retain) NSArray *sections;
@property (nonatomic, retain) NSDictionary *eventsBySection;
@property (nonatomic, retain) NSIndexPath *indexPath;
@property (nonatomic, retain) CalendarDataManager *dataManager;

- (void)setupTableView;

@end

