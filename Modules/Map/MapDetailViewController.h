#import <UIKit/UIKit.h>
#import "KGOTabbedViewController.h"
#import "KGODetailPager.h"

@class KGOPlacemark;

@interface MapDetailViewController : KGOTabbedViewController <KGODetailPagerDelegate, UIWebViewDelegate> {
    
}

@property (nonatomic, retain) KGOPlacemark *placemark;
@property (nonatomic, retain) KGODetailPager *pager;

@end
