#import <UIKit/UIKit.h>
#import "KGOShareButtonController.h"

@class KGOEventWrapper;

@interface EventDetailTableView : UITableView <UITableViewDelegate, UITableViewDataSource, KGOShareButtonDelegate> {
    
    NSArray *_sections;
    KGOEventWrapper *_event;

    UIButton *_shareButton;
    UIButton *_bookmarkButton;
    
    KGOShareButtonController *_shareController;
}

@property (nonatomic, retain) KGOEventWrapper *event;

- (void)showBookmarkButton;
- (void)showShareButton;

- (void)hideBookmarkButton;
- (void)hideShareButton;

@end
