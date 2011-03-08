#import <UIKit/UIKit.h>
#import "KGOTabbedViewController.h"
#import "KGODetailPager.h"

@class KGOPlacemark;

@interface MapDetailViewController : KGOTabbedViewController <KGODetailPagerDelegate> {
    
    UILabel *_titleLabel;
    UIView *_contentView;
    
}

@property (nonatomic, retain) KGOPlacemark *placemark;
@property (nonatomic, retain) KGODetailPager *pager;

@end
