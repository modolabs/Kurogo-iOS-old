/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"
#import "KGOSearchDisplayController.h"

@class KGOModule;
@class ModoSearchBar;
@class ModoNavigationBar;
@class ModoNavigationController;
@class FederatedSearchTableView;

@interface SpringboardViewController : KGOTableViewController <UISearchBarDelegate, KGOSearchDisplayDelegate> {

    UIScrollView *containingView;
    KGOModule *activeModule;
    ModoNavigationController *navigationController;
    ModoNavigationBar *navigationBar;
    KGOSearchDisplayController *_searchController;

    ModoSearchBar *_searchBar;
    BOOL isSearch;
    NSMutableArray *completedModules;
    
    NSMutableArray *_fixedIcons;
    NSMutableArray *_icons;
    NSMutableArray *editedIcons;
    NSMutableArray *tempIcons;
    UIButton *selectedIcon;
    UIButton *dummyIcon;
    NSInteger dummyIconIndex;
    UIView *transparentOverlay;
    
    CGPoint bottomRight;
    CGPoint startingPoint;
    
    BOOL editing;
}

- (void)layoutIcons:(NSArray *)icons horizontalSpacing:(CGFloat)spacing;
- (void)searchAllModules;

@property (nonatomic, assign) KGOModule *activeModule;
@property (nonatomic, retain) FederatedSearchTableView *searchResultsTableView;

@end



@interface SpringboardIcon : UIButton {
    NSString *moduleTag;
}

@property (nonatomic, retain) NSString *moduleTag;

@end
