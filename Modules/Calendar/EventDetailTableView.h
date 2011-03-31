#import <UIKit/UIKit.h>
#import "KGOShareButtonController.h"
#import "KGODetailPageHeaderView.h"

@class KGOEventWrapper;

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

@end
