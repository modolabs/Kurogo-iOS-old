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

@interface KGOSearchBarTextField : UITextField {
}

@end


@interface KGOSearchBar : UIView <UITextFieldDelegate> { // <UISearchBarDelegate> {

    // text field and cached properties
    KGOSearchBarTextField *_textField;
    UIButton *_bookmarkButton;
    
    // toolbar and cached properties
    KGOToolbar *_toolbar;
    UIColor *_toolbarTintColor;
    UIBarButtonItem *_cancelButton;
    NSArray *_hiddenToolbarItems;

    // scope buttons and cached properties
    UISegmentedControl *_scopeButtonControl;
    
    // decorative views
    UIImage *_backgroundImage;
    UIImage *_dropShadowImage;
    UIView *_backgroundView;
    UIView *_dropShadow;
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

#pragma mark Exposed methods and properties of text field

- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;

@property(nonatomic, copy) NSString *text;
@property(nonatomic, copy) NSString *placeholder;
@property(nonatomic, retain) UIFont *font;
@property(nonatomic, retain) UIColor *textColor;

// UITextInputTraits

@property(nonatomic) UIKeyboardType keyboardType;
@property(nonatomic) UIKeyboardAppearance keyboardAppearance;
@property(nonatomic) UITextAutocapitalizationType autocapitalizationType;
@property(nonatomic) UITextAutocorrectionType autocorrectionType;

// properties to mimic UISearchBar
@property(nonatomic) BOOL showsBookmarkButton;

#pragma mark Properties of attached toolbar

@property(nonatomic, retain) UIColor *tintColor;
@property(nonatomic) BOOL showsCancelButton;

- (void)setShowsCancelButton:(BOOL)showsCancelButton animated:(BOOL)animated;

#pragma mark Properties of segmented control -- unimplemeted

@property(nonatomic) BOOL showsScopeBar;
@property(nonatomic, copy) NSArray *scopeButtonTitles;
@property(nonatomic) NSInteger selectedScopeButtonIndex;

// not implementing the following until i see what they look like
//@property(nonatomic, copy) NSString *prompt;
//@property(nonatomic, getter=isSearchResultsButtonSelected) BOOL searchResultsButtonSelected;
//@property(nonatomic) BOOL showsSearchResultsButton;

// no longer implementing the following bar view properties
//@property(nonatomic) UIBarStyle barStyle;
//@property(nonatomic, assign, getter=isTranslucent) BOOL translucent;


@end
