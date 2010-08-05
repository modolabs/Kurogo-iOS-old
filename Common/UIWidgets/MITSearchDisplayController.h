#import <UIKit/UIKit.h>

/* 
 * This is an imitation of UISearchDisplayController
 * that makes the user responsible for hiding and showing
 * the search results table view.
 */

@interface MITSearchDisplayController : NSObject <UISearchBarDelegate> {
    
    UISearchBar *_searchBar;
    BOOL _active;
    
    // we make the delegate implement UISearchBarDelegate
    // and not UISearchDisplayDelegate because we don't have
    // a reasonable way to mimic or the latter's methods
    id<UISearchBarDelegate> _delegate;
    UIViewController *_searchContentsController;
    UITableView *_searchResultsTableView;
    id<UITableViewDataSource> _searchResultsDataSource;
    id<UITableViewDelegate> _searchResultsDelegate;

    UIControl *_searchOverlay;
    BOOL _searchResultsTableIsDefault;
}

@property(nonatomic, getter=isActive) BOOL active;
@property(nonatomic, assign) id<UISearchBarDelegate> delegate;
@property(nonatomic, readonly) UISearchBar *searchBar;
@property(nonatomic, readonly) UIViewController *searchContentsController;

// in UISearchDisplayController this has (retain) property
// we allow the searchResultsTableView to be overridden
// for example if we want a grouped tableView instead
@property(nonatomic, assign) UITableView *searchResultsTableView;
@property(nonatomic, assign) id<UITableViewDataSource> searchResultsDataSource;
@property(nonatomic, assign) id<UITableViewDelegate> searchResultsDelegate;

- (id)initWithSearchBar:(UISearchBar *)searchBar contentsController:(UIViewController *)viewController;
- (id)initWithFrame:(CGRect)frame searchBar:(UISearchBar *)searchBar contentsController:(UIViewController *)viewController;
- (void)setActive:(BOOL)visible animated:(BOOL)animated;

// give user access to more granular search UI states
- (void)focusSearchBarAnimated:(BOOL)animated;
- (void)unfocusSearchBarAnimated:(BOOL)animated;
- (void)showSearchOverlayAnimated:(BOOL)animated;

// -[MITSearchDisplayController hideSearchOverlayAnimated:]
// should typically be called after results are in shown.
// this is not necessary if searchResultsTableView is always on top.
- (void)hideSearchOverlayAnimated:(BOOL)animated;

@end
