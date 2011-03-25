#import <UIKit/UIKit.h>
#import "KGOShareButtonController.h"
#import "KGODetailPager.h"

@class KGOEventWrapper, EventDetailTableView;

@interface CalendarDetailViewController : UIViewController <KGOShareButtonDelegate,
KGODetailPagerController, KGODetailPagerDelegate> {
    
    EventDetailTableView *_tableView;
    KGOEventWrapper *_event;
    
    KGOShareButtonController *_shareController;
}

@property (nonatomic, retain) NSArray *sections;
@property (nonatomic, retain) NSDictionary *eventsBySection;
@property (nonatomic, retain) NSIndexPath *indexPath;

@end

