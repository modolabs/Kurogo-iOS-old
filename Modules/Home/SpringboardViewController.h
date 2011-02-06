/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"

@class MITModule;
@class ModoSearchBar;
@class ModoNavigationBar;
@class MITSearchDisplayController;
@class ModoNavigationController;
@class FederatedSearchTableView;

@interface SpringboardViewController : KGOTableViewController <UISearchBarDelegate> {

    UIScrollView *containingView;
    MITModule *activeModule;
    ModoNavigationController *navigationController;
    ModoNavigationBar *navigationBar;
    MITSearchDisplayController *_searchController;

    ModoSearchBar *_searchBar;
    NSMutableArray *searchableModules;
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

@property (nonatomic, assign) MITModule *activeModule;
@property (nonatomic, retain) FederatedSearchTableView *searchResultsTableView;
@property (nonatomic, readonly) NSArray *searchableModules;

@end



@interface SpringboardIcon : UIButton {
    NSString *moduleTag;
}

@property (nonatomic, retain) NSString *moduleTag;

@end
