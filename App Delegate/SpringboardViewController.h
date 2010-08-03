#import <UIKit/UIKit.h>
#import "MITModule.h"
#import "ModoNavigationController.h"
#import "ModoNavigationBar.h"
#import "ModoSearchBar.h"

@interface SpringboardViewController : UIViewController <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource> {

    UIScrollView *containingView;
    MITModule *activeModule;
    ModoNavigationController *navigationController;
    ModoNavigationBar *navigationBar;

    ModoSearchBar *_searchBar;
    NSMutableArray *searchableModules;
    BOOL isSearch;
    
    NSMutableArray *_icons;
    NSMutableArray *editedIcons;
    NSMutableArray *tempIcons;
    UIButton *selectedIcon;
    UIButton *dummyIcon;
    NSInteger dummyIconIndex;
    UIView *transparentOverlay;
    
    CGPoint topLeft;
    CGPoint bottomRight;
    CGPoint startingPoint;
    
    BOOL editing;
}

- (void)layoutIcons:(NSArray *)icons;
- (void)searchAllModules;

@property (nonatomic, retain) UITableView *searchResultsTableView;
@property (nonatomic, readonly) NSArray *searchableModules;

@end



@interface SpringboardIcon : UIButton {
    NSString *moduleTag;
}

@property (nonatomic, retain) NSString *moduleTag;

@end
