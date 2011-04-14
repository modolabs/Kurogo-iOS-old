#import <UIKit/UIKit.h>
#import "KGOShareButtonController.h"
#import "KGODetailPageHeaderView.h"
#import <MessageUI/MFMailComposeViewController.h>

@class KGOEventWrapper, CalendarDataManager;
@class CalendarDetailViewController;

@interface EventDetailTableView : UITableView <UITableViewDelegate,
UITableViewDataSource, KGODetailPageHeaderDelegate, MFMailComposeViewControllerDelegate> {
    
    NSArray *_sections;
    KGOEventWrapper *_event;

    UIButton *_shareButton;
    UIButton *_bookmarkButton;
    
    KGODetailPageHeaderView *_headerView;
    UILabel *_descriptionLabel;
}

@property (nonatomic, assign) CalendarDetailViewController *viewController;
@property (nonatomic, retain) KGOEventWrapper *event;
@property (nonatomic, retain) CalendarDataManager *dataManager;

// functions split out for subclassing

- (UIView *)viewForTableHeader;

- (NSArray *)sectionForBasicInfo;
- (NSArray *)sectionForAttendeeInfo;
- (NSArray *)sectionForContactInfo;
- (NSArray *)sectionForExtendedInfo;

@end
