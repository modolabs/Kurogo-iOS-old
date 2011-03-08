#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"
#import "KGORequestManager.h"

@protocol KGOCategory;

@interface KGOCategoryListViewController : KGOTableViewController <KGORequestDelegate> {

	UIView *_headerView;
	NSArray *_categories;

}

@property (nonatomic, retain) UIView *headerView;
@property (nonatomic, retain) NSArray *categories;
@property (nonatomic, retain) id<KGOCategory> parentCategory;
@property (nonatomic, retain) KGORequest *request;
@property (nonatomic, retain) NSString *entityName;

@end
