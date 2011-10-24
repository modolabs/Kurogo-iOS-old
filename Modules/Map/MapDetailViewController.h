#import <UIKit/UIKit.h>
#import "KGOTabbedViewController.h"
#import "KGODetailPager.h"
#import "KGOSearchModel.h"
#import "KGORequest.h"
#import "MapDataManager.h"

@class KGOPlacemark, KGOSearchResultListTableView;

@interface MapDetailViewController : KGOTabbedViewController <KGODetailPagerDelegate,
MapDataManagerDelegate, UIWebViewDelegate> {
    
    KGOSearchResultListTableView *_tableView;
    
    NSInteger _photoTabIndex;
    NSInteger _detailsTabIndex;
    NSInteger _nearbyTabIndex;
    
}

@property (nonatomic, retain) MapDataManager *dataManager;
@property (nonatomic, retain) KGOPlacemark *placemark;
@property (nonatomic, retain) KGODetailPager *pager;

@end
