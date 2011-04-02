#import <UIKit/UIKit.h>
#import "KGOShareButtonController.h"
#import "KGODetailPageHeaderView.h"

@class KGOEventWrapper, CalendarDataManager;

@interface EventDetailTableView : UITableView <UITableViewDelegate,
UITableViewDataSource, KGOShareButtonDelegate, KGODetailPageHeaderDelegate> {
    
    NSArray *_sections;
    KGOEventWrapper *_event;

    UIButton *_shareButton;
    UIButton *_bookmarkButton;
    
    KGOShareButtonController *_shareController;
    
    KGODetailPageHeaderView *_headerView;
    UILabel *_descriptionLabel;
}

@property (nonatomic, retain) KGOEventWrapper *event;
@property (nonatomic, retain) CalendarDataManager *dataManager;

// functions split out for subclassing

- (UIView *)viewForTableHeader;

- (NSArray *)sectionForBasicInfo;
- (NSArray *)sectionForAttendeeInfo;
- (NSArray *)sectionForContactInfo;
- (NSArray *)sectionForExtendedInfo;

@end
