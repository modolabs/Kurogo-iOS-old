/* A grouped table view controller that displays categories and automatically
 * drills down to their subcategories or leaf items.  Mixed lists containing
 * both category and leaf items are not supported right now.
 */
#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"
#import "KGORequestManager.h"
#import "MapDataManager.h"

@protocol KGOCategory;

@class MapDataManager;

@interface MapCategoryListViewController : KGOTableViewController //<KGORequestDelegate> {
<MapDataManagerDelegate>
{

	UIView *_headerView;
    KGORequest *_request;
    
    UIView *_loadingView;

}

@property (nonatomic, assign) MapDataManager *dataManager;
@property (nonatomic, retain) NSArray *listItems;
@property (nonatomic, retain) id<KGOCategory> parentCategory;

@property (nonatomic, retain) UIView *headerView;

- (void)showLoadingView;
- (void)hideLoadingView;

@end
