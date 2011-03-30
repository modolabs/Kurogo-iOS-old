#import <UIKit/UIKit.h>

// this isn't the right protocol to use, but anyone who implements this does
// what we need it to do.  TODO: find a way to share the didSelectResult:
// method that we want.
@protocol KGOSearchDisplayDelegate;

@interface KGOBookmarksViewController : UITableViewController {
    
    NSMutableArray *_mutableItems;
    
}

@property(nonatomic, retain) NSArray *bookmarkedItems;
@property(nonatomic, assign) id<KGOSearchDisplayDelegate> searchDisplayDelegate;

@end
