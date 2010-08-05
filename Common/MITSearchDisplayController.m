#import "MITSearchDisplayController.h"

@interface MITSearchDisplayController (Private)

- (void)searchOverlayTapped;
- (void)releaseSearchOverlay;

@end



@implementation MITSearchDisplayController

@synthesize searchBar = _searchBar, active = _active, delegate = _delegate,
searchContentsController = _searchContentsController,
searchResultsDelegate = _searchResultsDelegate,
searchResultsDataSource = _searchResultsDataSource,
searchResultsTableView = _searchResultsTableView;

#pragma mark Public

- (id)initWithSearchBar:(UISearchBar *)searchBar contentsController:(UIViewController *)viewController {
    if (self = [super init]) {
        _searchBar = searchBar;
        _searchBar.delegate = self;
        _searchContentsController = viewController;
        CGRect frame = CGRectMake(0.0, _searchBar.frame.size.height, viewController.view.frame.size.width,
                                  viewController.view.frame.size.height - _searchBar.frame.size.height);
        _searchResultsTableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
        _searchResultsTableIsDefault = YES;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame searchBar:(UISearchBar *)searchBar contentsController:(UIViewController *)viewController {
    if (self = [super init]) {
        _searchBar = searchBar;
        _searchBar.delegate = self;
        _searchContentsController = viewController;
        _searchResultsTableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
        _searchResultsTableIsDefault = YES;
    }
    return self;
}

- (void)setActive:(BOOL)visible animated:(BOOL)animated {
    _active = visible;

    if (_active) {
        [self focusSearchBarAnimated:animated];
        [self showSearchOverlayAnimated:animated];
    } else {
        [self unfocusSearchBarAnimated:animated];
        [self hideSearchOverlayAnimated:animated];
    }
}

#pragma mark Setters

- (void)setSearchResultsTableView:(UITableView *)tableView {
    if (_searchResultsTableView != tableView) {
        if (_searchResultsTableIsDefault)
            [_searchResultsTableView release];
        _searchResultsTableIsDefault = NO;
        _searchResultsTableView = tableView;
    }
}

// these are (assign) properties

- (void)setSearchResultsDelegate:(id<UITableViewDelegate>)delegate {
    _searchResultsDelegate = delegate;
    _searchResultsTableView.delegate = delegate;
}

- (void)setSearchResultsDataSource:(id<UITableViewDataSource>)dataSource {
    _searchResultsDataSource = dataSource;
    _searchResultsTableView.dataSource = dataSource;
}

- (void)dealloc {
    _searchResultsTableView.delegate = nil;
    _searchResultsTableView.dataSource = nil;
    if (_searchResultsTableIsDefault)
        [_searchResultsTableView release];
    [super dealloc];
}

#pragma mark Search UI (Private)

- (void)focusSearchBarAnimated:(BOOL)animated {
    [_searchBar setShowsCancelButton:YES animated:animated];
    [_searchBar becomeFirstResponder];
}

- (void)unfocusSearchBarAnimated:(BOOL)animated {
    [_searchBar setShowsCancelButton:NO animated:animated];
    [_searchBar resignFirstResponder];
}

- (void)showSearchOverlayAnimated:(BOOL)animated {
    if (!_searchOverlay) {
        CGFloat yOrigin = _searchBar.frame.origin.y + _searchBar.frame.size.height;

        if (_searchResultsTableView) {
            _searchOverlay = [[UIControl alloc] initWithFrame:_searchResultsTableView.frame];
        } else {
            // just in case user set searchResultsTableView to nil
            CGSize containerSize = _searchContentsController.view.frame.size;
            CGRect frame = CGRectMake(0.0, yOrigin, containerSize.width, containerSize.height - yOrigin);
            _searchOverlay = [[UIControl alloc] initWithFrame:frame];
        }
        
        _searchOverlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
        _searchOverlay.alpha = 0.0;
        [_searchOverlay addTarget:self action:@selector(searchOverlayTapped) forControlEvents:UIControlEventTouchDown];
    }

    [_searchContentsController.view addSubview:_searchOverlay];
    
    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.4];
        _searchOverlay.alpha = 1.0;
        [UIView commitAnimations];
    } else {
        _searchOverlay.alpha = 1.0;
    }
}

- (void)hideSearchOverlayAnimated:(BOOL)animated {
    if (_searchOverlay) {
        if (animated) {
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.4];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(releaseSearchOverlay)];
            _searchOverlay.alpha = 0.0;
            [UIView commitAnimations];
        } else {
            [self releaseSearchOverlay];
        }
    }
}

- (void)releaseSearchOverlay {
    [_searchOverlay removeFromSuperview];
    [_searchOverlay release];
    _searchOverlay = nil;
}

- (void)searchOverlayTapped {
    [self setActive:NO animated:YES];
    
    // this will not hide the searchResultsTableView,
    // have the delegate decide whether it is appropriate
    if ([self.delegate respondsToSelector:@selector(searchOverlayTapped)]) {
        // this is just a dumb way to dodge a compiler warning
        [self.delegate performSelector:@selector(searchOverlayTapped)];
    }
}

#pragma mark UISearchBarDelegate forwarding

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self setActive:YES animated:YES];
    
    if ([self.delegate respondsToSelector:@selector(searchBarTextDidBeginEditing:)]) {
        [self.delegate searchBarTextDidBeginEditing:searchBar];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    //[self setActive:NO animated:YES];
    [self unfocusSearchBarAnimated:YES];

    if ([self.delegate respondsToSelector:@selector(searchBarSearchButtonClicked:)]) {
        [self.delegate searchBarSearchButtonClicked:searchBar];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    if ([self.delegate respondsToSelector:@selector(searchBarCancelButtonClicked:)]) {
        [self.delegate searchBarCancelButtonClicked:searchBar];
    }
    
    [self setActive:NO animated:YES];
    
    _searchBar.text = nil;
    [_searchResultsTableView removeFromSuperview];
}

// the rest of this is pure forwarding

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    if ([self.delegate respondsToSelector:@selector(searchBarShouldBeginEditing:)]) {
        return [self.delegate searchBarShouldBeginEditing:searchBar];
    }
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    if ([self.delegate respondsToSelector:@selector(searchBarShouldEndEditing:)]) {
        return [self.delegate searchBarShouldEndEditing:searchBar];
    }
    return YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if ([self.delegate respondsToSelector:@selector(searchBarTextDidEndEditing:)]) {
        [self.delegate searchBarTextDidEndEditing:searchBar];
    }
}

- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar {
    if ([self.delegate respondsToSelector:@selector(searchBarResultsListButtonClicked:)]) {
        [self.delegate searchBarResultsListButtonClicked:searchBar];
    }
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar {
    if ([self.delegate respondsToSelector:@selector(searchBarBookmarkButtonClicked:)]) {
        [self.delegate searchBarBookmarkButtonClicked:searchBar];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([self.delegate respondsToSelector:@selector(searchBar:textDidChange:)]) {
        [self.delegate searchBar:searchBar textDidChange:searchText];
    }
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([self.delegate respondsToSelector:@selector(searchBar:shouldChangeTextInRange:replacementText:)]) {
        return [self.delegate searchBar:searchBar shouldChangeTextInRange:range replacementText:text];
    }
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    if ([self.delegate respondsToSelector:@selector(searchBar:selectedScopeButtonIndexDidChange:)]) {
        [self.delegate searchBar:searchBar selectedScopeButtonIndexDidChange:selectedScope];
    }
}

@end
