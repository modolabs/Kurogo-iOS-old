#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"
#import "IconGrid.h"
#import "KGOHomeScreenViewController.h"

@class KGOModule;
@class KGOSearchBar;

@interface KGOSpringboardViewController : KGOHomeScreenViewController <IconGridDelegate> {

    UIScrollView *_scrollView;
    
    IconGrid *primaryGrid;
    IconGrid *secondGrid;
}

@end

