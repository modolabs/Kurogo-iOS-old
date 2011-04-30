/* A grouped table view controller that displays categories and automatically
 * drills down to their subcategories or leaf items.  Mixed lists containing
 * both category and leaf items are not supported right now.
 */
#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"
#import "KGORequestManager.h"

@protocol KGOCategory;

@interface KGOCategoryListViewController : KGOTableViewController <KGORequestDelegate> {

	UIView *_headerView;
	NSArray *_categories;
    NSArray *_leafItems;
    KGORequest *_request;
    
    UIView *_loadingView;

}

@property (nonatomic, retain) UIView *headerView;

@property (nonatomic, retain) id<KGOCategory> parentCategory;
@property (nonatomic, retain) NSArray *categories;
@property (nonatomic, retain) NSArray *leafItems;

@property (nonatomic, retain) KGORequest *categoriesRequest;
@property (nonatomic, retain) NSString *categoryEntityName;

@property (nonatomic, retain) KGORequest *leafItemsRequest;
@property (nonatomic, retain) NSString *leafItemEntityName;

- (void)showLoadingView;
- (void)hideLoadingView;

@end
