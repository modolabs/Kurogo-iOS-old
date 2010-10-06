/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import <UIKit/UIKit.h>

@class MITModule;
@class ModoSearchBar;
@class ModoNavigationBar;
@class MITSearchDisplayController;
@class ModoNavigationController;

@interface SpringboardViewController : UIViewController <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource> {

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

@property (nonatomic, retain) UITableView *searchResultsTableView;
@property (nonatomic, readonly) NSArray *searchableModules;

@end



@interface SpringboardIcon : UIButton {
    NSString *moduleTag;
}

@property (nonatomic, retain) NSString *moduleTag;

@end
