/*
 * this class is a wrapper of UISearchBar that
 * gives us the ability to add arbitrary toolbar buttons
 * on the right side.
 */

#import <UIKit/UIKit.h>

@class KGOSearchBar;

@protocol KGOSearchBarDelegate <NSObject>

@optional

- (void)toolbarItemTapped:(UIBarButtonItem *)item;

- (void)searchBarTextDidBeginEditing:(KGOSearchBar *)searchBar;
- (void)searchBarSearchButtonClicked:(KGOSearchBar *)searchBar;
- (void)searchBarCancelButtonClicked:(KGOSearchBar *)searchBar;
- (void)searchBarBookmarkButtonClicked:(KGOSearchBar *)searchBar;
- (void)searchBar:(KGOSearchBar *)searchBar textDidChange:(NSString *)searchText;
- (void)searchBar:(KGOSearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope;

@end


@class KGOToolbar;

@interface KGOSearchBar : UIView <UISearchBarDelegate> {
    
    UIImage *_backgroundImage;
    UIImage *_dropShadowImage;
    
    UISearchBar *_searchBar;
    UIView *_backgroundView;
    UIView *_dropShadow;
    KGOToolbar *_toolbar;
}

- (void)addToolbarButton:(UIBarButtonItem *)aButton animated:(BOOL)animated;
- (void)addToolbarButtonWithTitle:(NSString *)title;
- (void)addToolbarButtonWithImage:(UIImage *)image;

- (void)setToolbarItems:(NSArray *)items animated:(BOOL)animated;

- (void)hideToolbarAnimated:(BOOL)animated;
- (void)showToolbarAnimated:(BOOL)animated;

@property(nonatomic, copy) NSArray *toolbarItems;

@property(nonatomic, retain) UIImage *backgroundImage;
@property(nonatomic, retain) UIImage *dropShadowImage;

@property(nonatomic, assign) id<KGOSearchBarDelegate> delegate;

#pragma mark UISearchBar tasks

@property(nonatomic) UITextAutocapitalizationType autocapitalizationType;
@property(nonatomic) UITextAutocorrectionType autocorrectionType;
@property(nonatomic) UIBarStyle barStyle;
@property(nonatomic) UIKeyboardType keyboardType;
@property(nonatomic, copy) NSString *placeholder;
@property(nonatomic, copy) NSString *prompt;
@property(nonatomic, copy) NSArray *scopeButtonTitles;
@property(nonatomic, getter=isSearchResultsButtonSelected) BOOL searchResultsButtonSelected;
@property(nonatomic) NSInteger selectedScopeButtonIndex;
@property(nonatomic) BOOL showsBookmarkButton;
@property(nonatomic) BOOL showsCancelButton;
@property(nonatomic) BOOL showsScopeBar;
@property(nonatomic) BOOL showsSearchResultsButton;
@property(nonatomic, copy) NSString *text;
@property(nonatomic, retain) UIColor *tintColor;
@property(nonatomic, assign, getter=isTranslucent) BOOL translucent;

- (void)setShowsCancelButton:(BOOL)showsCancelButton animated:(BOOL)animated;

@end
