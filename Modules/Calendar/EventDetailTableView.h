#import <UIKit/UIKit.h>
#import "KGOShareButtonController.h"

@class KGOEventWrapper;
@class KGODetailPageHeaderView;

@interface EventDetailTableView : UITableView <UITableViewDelegate, UITableViewDataSource, KGOShareButtonDelegate> {
    
    NSArray *_sections;
    KGOEventWrapper *_event;

    UIButton *_shareButton;
    UIButton *_bookmarkButton;
    
    KGOShareButtonController *_shareController;
    
    KGODetailPageHeaderView *_headerView;
}

@property (nonatomic, retain) KGOEventWrapper *event;

@end
