#import <UIKit/UIKit.h>
#import "KGOShareButtonController.h"
#import "KGODetailPageHeaderView.h"

@interface EventDetailTableHeader : KGODetailPageHeaderView {
    
    UILabel *_descriptionLabel;

}

@property (nonatomic, readonly) UILabel *descriptionLabel;

@end


@class KGOEventWrapper;


@interface EventDetailTableView : UITableView <UITableViewDelegate, UITableViewDataSource, KGOShareButtonDelegate> {
    
    NSArray *_sections;
    KGOEventWrapper *_event;

    UIButton *_shareButton;
    UIButton *_bookmarkButton;
    
    KGOShareButtonController *_shareController;
    
    EventDetailTableHeader *_headerView;
}

@property (nonatomic, retain) KGOEventWrapper *event;

@end
