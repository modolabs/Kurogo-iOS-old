#import "KGOSearchBar.h"
#import "KGOTheme.h"
#import "KGOToolbar.h"

#define TOOLBAR_BUTTON_PADDING 4.0
#define TOOLBAR_SEARCHBAR_OVERLAP 4.0
#define TOOLBAR_BUTTON_SPACING 6.0

@implementation KGOSearchBar

@synthesize delegate;

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        _searchBar = [[UISearchBar alloc] initWithCoder:aDecoder]; // do this first so _searchBar can receive setter methods right away
        _searchBar.delegate = self;

        UIColor *color = [[KGOTheme sharedTheme] tintColorForSearchBar];
        if (color) {
            _searchBar.tintColor = color;
        }
        UIImage *image = [[[KGOTheme sharedTheme] backgroundImageForSearchBar] stretchableImageWithLeftCapWidth:15 topCapHeight:0];
        if (image) {
            self.backgroundImage = image;
        }
        image = [[KGOTheme sharedTheme] backgroundImageForSearchBarDropShadow];
        if (image) {
            self.dropShadowImage = image;
        }
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        _searchBar = [[UISearchBar alloc] initWithFrame:frame]; // do this first so _searchBar can receive setter methods right away
        _searchBar.delegate = self;

        UIColor *color = [[KGOTheme sharedTheme] tintColorForSearchBar];
        if (color) {
            _searchBar.tintColor = color;
        }
        UIImage *image = [[KGOTheme sharedTheme] backgroundImageForSearchBar];
        if (image) {
            self.backgroundImage = image;
        }
        image = [[KGOTheme sharedTheme] backgroundImageForSearchBarDropShadow];
        if (image) {
            self.dropShadowImage = image;
        }
    }
    return self;
}

// TODO: search bars have a minimum size restriction, need to make sure KGOSearchBar isn't created smaller
- (void)layoutSubviews {
    // sad way to use a background image for a search bar:
    // insert the image right below the text field
    if (self.backgroundImage) {
        _backgroundView = [[UIImageView alloc] initWithImage:[self.backgroundImage stretchableImageWithLeftCapWidth:0 topCapHeight:0]];
        _backgroundView.autoresizingMask = self.autoresizingMask;
        _backgroundView.frame = _searchBar.frame;
        NSInteger viewIndex = 0;
        for (UIView *aView in _searchBar.subviews) {
            if ([aView isKindOfClass:[UITextField class]]) {
                break;
            }
            viewIndex++;
        }
        [_searchBar insertSubview:_backgroundView atIndex:viewIndex];
    }
    
    if (self.dropShadowImage) {
        self.clipsToBounds = NO;
        _dropShadow = [[UIImageView alloc] initWithImage:[self.dropShadowImage stretchableImageWithLeftCapWidth:0 topCapHeight:0]];
        _dropShadow.autoresizingMask = self.autoresizingMask;
        _dropShadow.frame = CGRectMake(0, _searchBar.frame.size.height, _searchBar.frame.size.width, _dropShadow.frame.size.height);
        [self addSubview:_dropShadow];
    }
    
    NSLog(@"%@ %@ %@ %@", self, _backgroundView, _dropShadow, _searchBar);
    
    if (![_searchBar isDescendantOfView:self]) {
        [self addSubview:_searchBar];
    }
    
    if (![_toolbar isDescendantOfView:self]) {
        [self addSubview:_toolbar];
    }
}

- (void)setNeedsLayout {
    [super setNeedsLayout];
    
    if (self.backgroundImage && _backgroundView) {
        [_backgroundView removeFromSuperview];
        [_backgroundView release];
        _backgroundView = nil;
    }
    if (self.dropShadowImage && _dropShadow) {
        [_dropShadow removeFromSuperview];
        [_dropShadow release];
        _dropShadow = nil;
    }
}

- (void)dealloc {
    self.backgroundImage = nil;
    self.dropShadowImage = nil;
    [_backgroundView release];
    [_dropShadow release];
    [_searchBar release];
    [_toolbar release];
    [super dealloc];
}

#pragma mark Extra views

- (UIImage *)backgroundImage {
    return _backgroundImage;
}

- (void)setBackgroundImage:(UIImage *)image {
    [_backgroundImage release];
    _backgroundImage = [image retain];

    if (_backgroundImage) {
        _toolbar.backgroundColor = [UIColor clearColor];
    }
}

- (UIImage *)dropShadowImage {
    return _dropShadowImage;
}

- (void)setDropShadowImage:(UIImage *)image {
    [_dropShadowImage release];
    _dropShadowImage = [image retain];
}

#pragma mark Toolbar

- (void)hideToolbarAnimated:(BOOL)animated {
    if (_toolbar) {
        if (animated) {
            [UIView beginAnimations:@"searching" context:nil];
            [UIView setAnimationDuration:0.4];
        }
        _toolbar.alpha = 0.0;
        _searchBar.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        if (animated) {
            [UIView commitAnimations];
        }
    }
}

- (void)showToolbarAnimated:(BOOL)animated {
    if (_toolbar) {
        if (animated) {
            [UIView beginAnimations:@"searching" context:nil];
            [UIView setAnimationDuration:0.4];
        }
        _toolbar.alpha = 1.0;
        _searchBar.frame = CGRectMake(0.0f, 0.0f, self.frame.size.width - _toolbar.frame.size.width + TOOLBAR_SEARCHBAR_OVERLAP, self.frame.size.height);
        if (animated) {
            [UIView commitAnimations];
        }
    }
}

- (NSArray *)toolbarItems {
    if (_toolbar) {
        return _toolbar.items;
    }
    return nil;
}

- (void)setToolbarItems:(NSArray *)items {
    [self setToolbarItems:items animated:NO];
}

- (void)setToolbarItems:(NSArray *)items animated:(BOOL)animated {
    // get toolbar size
    CGRect frame = CGRectZero;
    frame.size.height = self.frame.size.height;
    CGFloat width = items.count ? TOOLBAR_BUTTON_SPACING : 0.0;
    for (UIBarButtonItem *anItem in items) {
        width += anItem.width + TOOLBAR_BUTTON_SPACING;
    }
    frame.size.width = width;
    
    // adjust search bar size
    CGFloat searchBarWidth = self.frame.size.width - width;
    frame.origin.x = searchBarWidth;
    _searchBar.frame = CGRectMake(0, 0, searchBarWidth + TOOLBAR_SEARCHBAR_OVERLAP, self.frame.size.height);
    
    // construct toolbar
    if (!_toolbar) {
        _toolbar = [[KGOToolbar alloc] initWithFrame:frame];
        _toolbar.tintColor = _searchBar.tintColor;
        if (!self.backgroundImage) {
            _toolbar.translucent = [_searchBar isTranslucent];
            _toolbar.barStyle = _searchBar.barStyle;
        } else {
            _toolbar.backgroundImage = self.backgroundImage;
        }
        [self addSubview:_toolbar];
        
    } else {
        _toolbar.frame = frame;
    }
    [_toolbar setItems:items animated:animated];
}

- (void)addToolbarButton:(UIBarButtonItem *)aButton animated:(BOOL)animated {
    NSMutableArray *currentButtons = [[_toolbar.items mutableCopy] autorelease];
    if (!currentButtons) {
        currentButtons = [NSMutableArray array];
    }
    [currentButtons addObject:aButton];
    [self setToolbarItems:currentButtons animated:animated];
}

- (void)addToolbarButtonWithTitle:(NSString *)title {
    UIBarButtonItem *item = [[[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStyleBordered target:self action:@selector(toolbarItemTapped:)] autorelease];
    item.width = [title sizeWithFont:[UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]]].width + 2 * TOOLBAR_BUTTON_PADDING;
    [self addToolbarButton:item animated:NO];
}

- (void)addToolbarButtonWithImage:(UIImage *)image {
    UIBarButtonItem *item = [[[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStyleBordered target:self action:@selector(toolbarItemTapped:)] autorelease];
    item.width = image.size.width + 2 * TOOLBAR_BUTTON_PADDING;
    [self addToolbarButton:item animated:NO];
}

- (void)toolbarItemTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(toolbarItemTapped:)]) {
        if ([sender isKindOfClass:[UIBarButtonItem class]]) {
            [self.delegate toolbarItemTapped:(UIBarButtonItem *)sender];
        }
    }
}

#pragma mark UISearchBar delegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    if ([self.delegate respondsToSelector:@selector(searchBarTextDidBeginEditing:)]) {
        [self.delegate searchBarTextDidBeginEditing:self];
    }
    [self hideToolbarAnimated:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    if ([self.delegate respondsToSelector:@selector(searchBarSearchButtonClicked:)]) {
        [self.delegate searchBarSearchButtonClicked:self];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    if ([self.delegate respondsToSelector:@selector(searchBarCancelButtonClicked:)]) {
        [self.delegate searchBarCancelButtonClicked:self];
    }
    [self showToolbarAnimated:YES];
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar {
    if ([self.delegate respondsToSelector:@selector(searchBarBookmarkButtonClicked:)]) {
        [self.delegate searchBarBookmarkButtonClicked:self];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([self.delegate respondsToSelector:@selector(searchBar:textDidChange:)]) {
        [self.delegate searchBar:self textDidChange:searchText];
    }
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    if ([self.delegate respondsToSelector:@selector(searchBar:selectedScopeButtonIndexDidChange:)]) {
        [self.delegate searchBar:self selectedScopeButtonIndexDidChange:selectedScope];
    }
}

#pragma mark UIResponder

- (BOOL)becomeFirstResponder {
    return [_searchBar becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    return [_searchBar resignFirstResponder];
}

#pragma mark UISearchBar tasks

- (UITextAutocapitalizationType) autocapitalizationType {
    return _searchBar.autocapitalizationType;
}

- (void)setAutocapitalizationType:(UITextAutocapitalizationType)type {
    _searchBar.autocapitalizationType = type;
}

- (UITextAutocorrectionType) autocorrectionType {
    return _searchBar.autocapitalizationType;
}

- (void)setAutocorrectionType:(UITextAutocorrectionType)type {
    _searchBar.autocorrectionType = type;
}

- (UIBarStyle)barStyle {
    return _searchBar.barStyle;
}

- (void)setBarStyle:(UIBarStyle)style {
    _searchBar.barStyle = style;
    if (!self.backgroundImage) {
        _toolbar.barStyle = style;
    }
}

- (UIKeyboardType)keyboardType {
    return _searchBar.keyboardType;
}

- (void)setKeyboardType:(UIKeyboardType)type {
    _searchBar.keyboardType = type;
}

- (NSString *)placeholder {
    return _searchBar.placeholder;
}

- (void)setPlaceholder:(NSString *)placeholder {
    _searchBar.placeholder = placeholder;
}

- (NSString *)prompt {
    return _searchBar.prompt;
}

- (void)setPrompt:(NSString *)prompt {
    _searchBar.prompt = prompt;
}

- (NSArray *)scopeButtonTitles {
    return _searchBar.scopeButtonTitles;
}

- (void)setScopeButtonTitles:(NSArray *)titles {
    _searchBar.scopeButtonTitles = titles;
}

- (BOOL)isSearchResultsButtonSelected {
    return [_searchBar isSearchResultsButtonSelected];
}

- (void)setSearchResultsButtonSelected:(BOOL)selected {
    _searchBar.searchResultsButtonSelected = selected;
}

- (NSInteger)selectedScopeButtonIndex {
    return _searchBar.selectedScopeButtonIndex;
}

- (void)setSelectedScopeButtonIndex:(NSInteger)index {
    _searchBar.selectedScopeButtonIndex = index;
}

- (BOOL)showsBookmarkButton {
    return _searchBar.showsBookmarkButton;
}

- (void)setShowsBookmarkButton:(BOOL)shows {
    _searchBar.showsBookmarkButton = shows;
}

- (BOOL)showsCancelButton {
    return _searchBar.showsCancelButton;
}

- (void)setShowsCancelButton:(BOOL)shows {
    _searchBar.showsCancelButton = shows;
}

- (BOOL)showsScopeBar {
    return _searchBar.showsScopeBar;
}

- (void)setShowsScopeBar:(BOOL)shows {
    _searchBar.showsScopeBar = shows;
}

- (BOOL)showsSearchResultsButton {
    return _searchBar.showsSearchResultsButton;
}

- (void)setShowsSearchResultsButton:(BOOL)shows {
    _searchBar.showsSearchResultsButton = shows;
}

- (NSString *)text {
    return _searchBar.text;
}

- (void)setText:(NSString *)text {
    _searchBar.text = text;
}

- (UIColor *)tintColor {
    return _searchBar.tintColor;
}

- (void)setTintColor:(UIColor *)color {
    _searchBar.tintColor = color;
    _toolbar.tintColor = color;
}

- (BOOL)isTranslucent {
    return [_searchBar isTranslucent];
}

- (void)setTranslucent:(BOOL)translucent {
    _searchBar.translucent = translucent;
    if (!self.backgroundImage) {
        _toolbar.translucent = translucent;
    }
}

- (void)setShowsCancelButton:(BOOL)showsCancelButton animated:(BOOL)animated {
    [_searchBar setShowsCancelButton:showsCancelButton animated:animated];
    if (showsCancelButton) {
        [self hideToolbarAnimated:animated];
    } else {
        [self showToolbarAnimated:animated];
    }
}

@end
