#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"

@interface FederatedSearchTableView : UITableView <KGOTableViewDataSource> {
	
}

@property (nonatomic, retain) NSArray *searchableModules;
@property (nonatomic, retain) NSString *query;

@end
