#import <UIKit/UIKit.h>
#import "KGOTabbedViewController.h"
#import "KGODetailPager.h"

@class KGOPlacemark;

@interface MapDetailViewController : KGOTabbedViewController <KGODetailPagerDelegate> {
    
    UILabel *_titleLabel;
    UIView *_contentView;
    
    UIButton *_bookmarkButton;
    
}

@property (nonatomic, retain) KGOPlacemark *placemark;
@property (nonatomic, retain) KGODetailPager *pager;

// TODO: there needs to be a universal bookmark ui
- (void)showBookmarkButton;
- (void)hideBookmarkButton;

@end
