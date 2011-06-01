#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"
#import "KGOSearchModel.h"
#import "KGOSearchDisplayController.h"

@interface KGOSearchResultListTableView : UITableView <KGOTableViewDataSource, KGOSearchResultsHolder> {
    
    KGOTableController *_tableController;
    
}

// must be an array of id<KGOSearchResult> items
@property(nonatomic, retain) NSArray *items;

@property(nonatomic, retain) id<KGOSearchResultsDelegate> resultsDelegate;

@end
