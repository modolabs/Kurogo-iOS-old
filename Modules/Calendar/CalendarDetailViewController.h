#import <UIKit/UIKit.h>
#import "KGODetailPager.h"

@class KGOEventWrapper, EventDetailTableView;

@interface CalendarDetailViewController : UIViewController <KGODetailPagerController, KGODetailPagerDelegate> {
    
    EventDetailTableView *_tableView;
    KGOEventWrapper *_event;
}

@property (nonatomic, retain) NSArray *sections;
@property (nonatomic, retain) NSDictionary *eventsBySection;
@property (nonatomic, retain) NSIndexPath *indexPath;

@end

