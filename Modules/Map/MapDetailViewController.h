#import <UIKit/UIKit.h>
#import "KGOTabbedViewController.h"
#import "KGODetailPager.h"
#import "KGOSearchModel.h"
#import "KGORequest.h"
#import "MapDataManager.h"
#import "KGOSearchDisplayController.h"

@class KGOPlacemark, KGOSearchResultListTableView, MapModule;


@interface MapDetailViewController : KGOTabbedViewController <KGOSearchResultsDelegate, KGOSearchResultsHolder, KGODetailPagerDelegate,
MapDataManagerDelegate, UIWebViewDelegate> {
    
    UIWebView *_webView;
    KGOSearchResultListTableView *_tableView;
    
    NSInteger _photoTabIndex;
    NSInteger _detailsTabIndex;
    NSInteger _nearbyTabIndex;
    
}

@property (nonatomic, retain) MapDataManager *dataManager;
@property (nonatomic, retain) KGOPlacemark *placemark;
@property (nonatomic, retain) KGODetailPager *pager;
@property (nonatomic, retain) MapModule *mapModule;

@end
