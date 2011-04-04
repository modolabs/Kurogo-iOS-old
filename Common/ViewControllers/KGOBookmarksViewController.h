#import <UIKit/UIKit.h>
#import "KGOSearchModel.h"

@protocol KGOSearchResultsDelegate;

@interface KGOBookmarksViewController : UITableViewController <KGOSearchResultsHolder> {
    
    NSMutableArray *_mutableItems;
    
}

@property(nonatomic, retain) NSArray *bookmarkedItems;
@property(nonatomic, assign) id<KGOSearchResultsDelegate> searchResultsDelegate;

@end
