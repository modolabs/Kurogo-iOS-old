#import <UIKit/UIKit.h>

@class KGOEventWrapper;

@interface EventDetailTableView : UITableView <UITableViewDelegate, UITableViewDataSource> {
    
    NSArray *_sections;
    KGOEventWrapper *_event;

}

@property (nonatomic, retain) KGOEventWrapper *event;

@end
