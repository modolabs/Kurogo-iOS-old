#import <UIKit/UIKit.h>
#import "KGOTabbedViewController.h"
#import "KGODetailPager.h"
#import "KGOSearchModel.h"
#import "KGORequest.h"

@class KGOPlacemark, KGOSearchResultListTableView;

@interface MapDetailViewController : KGOTabbedViewController <KGODetailPagerDelegate, UIWebViewDelegate, KGORequestDelegate> {
    
    KGORequest *_request;
    KGOSearchResultListTableView *_tableView;
    
    NSInteger _photoTabIndex;
    NSInteger _detailsTabIndex;
    NSInteger _nearbyTabIndex;
    
}

@property (nonatomic, retain) KGOPlacemark *placemark;
@property (nonatomic, retain) KGODetailPager *pager;

@end
