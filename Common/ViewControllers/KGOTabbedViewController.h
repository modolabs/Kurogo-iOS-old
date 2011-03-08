#import <UIKit/UIKit.h>
#import "TabViewControl.h"

@protocol KGOTabbedViewDelegate <NSObject>

- (UIView *)tabbedControl:(KGOTabbedControl *)control containerViewAtIndex:(NSInteger)index;
- (NSArray *)itemsForTabbedControl:(KGOTabbedControl *)control;

@end

@interface KGOTabbedViewController : UIViewController <KGOTabbedControlDelegate, KGOTabbedViewDelegate> {
    
    IBOutlet KGOTabbedControl *_tabs;
    IBOutlet UIView *_tabViewHeader;
    IBOutlet UIView *_tabViewContainer;
    
}

@property (nonatomic, assign) id<KGOTabbedViewDelegate> delegate;
@property (nonatomic, retain) UIView *tabViewHeader;
@property (nonatomic, retain) KGOTabbedControl *tabs;

- (void)reloadTabContent;

@end
