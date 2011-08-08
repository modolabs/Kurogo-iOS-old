#import <UIKit/UIKit.h>
#import "KGODetailPager.h"
#import <EventKitUI/EventKitUI.h>

@class KGOEventWrapper, EventDetailTableView, CalendarDataManager, KGOShareButtonController;

@interface CalendarDetailViewController : UIViewController <KGODetailPagerController, KGODetailPagerDelegate, EKEventEditViewDelegate> {
    
    EventDetailTableView *_tableView;
    KGOEventWrapper *_event;
    
    KGOShareButtonController *_shareController;
}

@property (nonatomic, retain) NSArray *sections;
@property (nonatomic, retain) NSDictionary *eventsBySection;
@property (nonatomic, retain) NSIndexPath *indexPath;
@property (nonatomic, retain) CalendarDataManager *dataManager;

- (void)setupTableView;
- (void)shareButtonPressed:(id)sender;

@end

