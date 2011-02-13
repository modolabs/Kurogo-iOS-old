#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"

@interface KGOCategoryListViewController : KGOTableViewController {

	UIView *_headerView;
	NSArray *_categories;
}

@property (nonatomic, retain) UIView *headerView;
@property (nonatomic, retain) NSArray *categories;

@end
