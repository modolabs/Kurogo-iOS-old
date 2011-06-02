#import "KGOSearchBar.h"
#import "KGOTheme.h"
#import "KGOToolbar.h"
#import "UIKit+KGOAdditions.h"
#import <QuartzCore/QuartzCore.h>

#define TOOLBAR_BUTTON_PADDING 5
#define TOOLBAR_BUTTON_SPACING 6
#define TOOLBAR_MINIMUM_WIDTH 1
#define TOOLBAR_ANIMATION_DURATION 0.3

// the toolbar provides too much padding by default
#define TEXTFIELD_RIGHT_ALLOWANCE 4

#define SEARCH_BAR_HEIGHT 44

#define TEXTFIELD_VERTICAL_PADDING 6
#define TEXTFIELD_HORIZONTAL_PADDING 6

@implementation KGOSearchBarTextField

- (void)layoutSubviews
{
    // UITextField by default attaches an animation to the text label the first
    // time it replaces the editing text, which causes the text to fly in from
    // the top left.  not sure why it does this, but for now we'll remove all
    // animations on labels since any SDK change will be at most cosmetic.
    for (UIView *aView in self.subviews) {
        if ([aView isKindOfClass:[UILabel class]]) {
            [aView.layer removeAllAnimations];
        }
    }
    [super layoutSubviews];
}

// TODO: stop hardcoding these numbers when we decide what looks right.

- (CGRect)leftViewRectForBounds:(CGRect)bounds
{
    CGRect rect = bounds;
    rect.origin.x = 6;
    rect.origin.y = 7;
    rect.size.width = 20;
    rect.size.height = bounds.size.height - 14;
    
    return rect;
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
    CGRect rect = bounds;
    rect.origin.x = 26;
    rect.origin.y = 7;
    rect.size.width = bounds.size.width - 12 - 20;
    rect.size.height = bounds.size.height - 14;
    
    return rect;
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds
{
    return [self textRectForBounds:bounds];
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return [self textRectForBounds:bounds];
}

@end

@interface KGOSearchBar (Private)

- (void)setupBackgroundView; // ensures that background image is bottommost view
- (void)setupTextField;
- (void)setupToolbar;

@end


@implementation KGOSearchBar

@synthesize delegate;

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        UIColor *color = [[KGOTheme sharedTheme] tintColorForSearchBar];
        if (color) {
            self.tintColor = color;
        }
        UIImage *image = [[KGOTheme sharedTheme] backgroundImageForSearchBar];
        if (image) {
            self.backgroundImage = image;
        }
        image = [[KGOTheme sharedTheme] backgroundImageForSearchBarDropShadow];
        if (image) {
            self.dropShadowImage = image;
        }
        
        [self setupToolbar];
        [self setupTextField];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        UIColor *color = [[KGOTheme sharedTheme] tintColorForSearchBar];
        if (color) {
            self.tintColor = color;
        }
        UIImage *image = [[KGOTheme sharedTheme] backgroundImageForSearchBar];
        if (image) {
            self.backgroundImage = image;
        }
        image = [[KGOTheme sharedTheme] backgroundImageForSearchBarDropShadow];
        if (image) {
            self.dropShadowImage = image;
        }
        
        [self setupToolbar];
        [self setupTextField];
    }
    return self;
}

- (void)dealloc {
    self.backgroundImage = nil; // releases _backgroundImage, _backgroundView
    self.dropShadowImage = nil; // releases _dropShadowImage, _dropShadow

    [_textField release];
    [_bookmarkButton release];

    [_toolbar release];
    [_toolbarTintColor release];
    [_hiddenToolbarItems release];
    [_cancelButton release];

    [_scopeButtonControl release];

    [super dealloc];
}

#pragma mark Subview creation

- (UIImage *)backgroundImage {
    return _backgroundImage;
}

- (void)setBackgroundImage:(UIImage *)image {
    [_backgroundImage release];
    _backgroundImage = [image retain];
    
    [self setupBackgroundView];
}

- (UIImage *)dropShadowImage {
    return _dropShadowImage;
}

- (void)setDropShadowImage:(UIImage *)image {
    [_dropShadowImage release];
    _dropShadowImage = [image retain];
    
    if (_dropShadowImage) {
        if (!_dropShadow) {
            _dropShadow = [[UIImageView alloc] initWithImage:[self.dropShadowImage stretchableImageWithLeftCapWidth:0 topCapHeight:0]];
            _dropShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            _dropShadow.frame = CGRectMake(0, self.frame.size.height, self.frame.size.width, _dropShadow.frame.size.height);
            [self addSubview:_dropShadow];
        }
        
    } else if (_dropShadow) {
        [_dropShadow removeFromSuperview];
        [_dropShadow release];
        _dropShadow = nil;
    }
}

- (void)setupToolbar
{
    if (!_toolbar) {
        CGRect frame = CGRectMake(self.frame.size.width - TOOLBAR_MINIMUM_WIDTH, 0, TOOLBAR_MINIMUM_WIDTH, self.frame.size.height);
        _toolbar = [[KGOToolbar alloc] initWithFrame:frame];
        _toolbar.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
        _toolbar.backgroundColor = [UIColor clearColor];
        _toolbar.backgroundImage = [UIImage imageWithPathName:@"common/action-blank"]; // transparent image
        _toolbar.tintColor = self.tintColor;

        [self addSubview:_toolbar];
    }
}

- (void)setupTextField
{
    CGRect frame = CGRectMake(TEXTFIELD_HORIZONTAL_PADDING, TEXTFIELD_VERTICAL_PADDING,
                              self.frame.size.width - TOOLBAR_MINIMUM_WIDTH - TEXTFIELD_HORIZONTAL_PADDING * 2,
                              self.frame.size.height - TEXTFIELD_VERTICAL_PADDING * 2);
    _textField = [[KGOSearchBarTextField alloc] initWithFrame:frame];
    _textField.leftView = [[[UIImageView alloc] initWithImage:[UIImage imageWithPathName:@"common/search_gray"]] autorelease];
    _textField.leftViewMode = UITextFieldViewModeAlways;
    _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _textField.returnKeyType = UIReturnKeySearch;
    _textField.background = [[UIImage imageWithPathName:@"common/search_bar_text_field"] stretchableImageWithLeftCapWidth:20
                                                                                                             topCapHeight:0];
    _textField.font = [UIFont systemFontOfSize:14];
    _textField.delegate = self;
    
    [self addSubview:_textField];
}

- (void)setupBackgroundView
{
    if (self.backgroundImage) {
        if (!_backgroundView) {
            _backgroundView = [[UIImageView alloc] initWithImage:[self.backgroundImage stretchableImageWithLeftCapWidth:0
                                                                                                           topCapHeight:0]];
            _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            _backgroundView.frame = self.frame;
        }
        
        if (self.subviews.count) {
            [self insertSubview:_backgroundView atIndex:0];
            
        } else {
            [self addSubview:_backgroundView];
        }
        
    } else if (_backgroundView) {
        [_backgroundView removeFromSuperview];
        [_backgroundView release];
        _backgroundView = nil;
    }
}

#pragma mark Toolbar

- (void)hideToolbarAnimated:(BOOL)animated {
    if (_toolbar.items.count) {
        _hiddenToolbarItems = [_toolbar.items copy];
        [self setToolbarItems:nil animated:animated];
    }
}

- (void)showToolbarAnimated:(BOOL)animated {
    if (_hiddenToolbarItems) {
        [self setToolbarItems:_hiddenToolbarItems animated:animated];
        [_hiddenToolbarItems release];
        _hiddenToolbarItems = nil;
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
    CGFloat toolbarWidth = TOOLBAR_MINIMUM_WIDTH;
    for (UIBarButtonItem *anItem in items) {
        toolbarWidth += anItem.width + TOOLBAR_BUTTON_SPACING + 10;
    }
    CGRect toolbarFrame = CGRectMake(self.frame.size.width - toolbarWidth, 0, toolbarWidth, self.frame.size.height);
    CGFloat textFieldWidth = self.frame.size.width - toolbarWidth - TEXTFIELD_HORIZONTAL_PADDING + TEXTFIELD_RIGHT_ALLOWANCE;
    if (!items.count) {
        textFieldWidth -= TEXTFIELD_HORIZONTAL_PADDING; // keep left/right margins symmetric when no buttons are present
    }
    CGRect textFieldFrame = CGRectMake(TEXTFIELD_HORIZONTAL_PADDING, TEXTFIELD_VERTICAL_PADDING,
                                       textFieldWidth,
                                       self.frame.size.height - TEXTFIELD_VERTICAL_PADDING * 2);
    if (animated) {
        [_toolbar setItems:items animated:YES];
        [UIView animateWithDuration:TOOLBAR_ANIMATION_DURATION animations:^(void) {
            _toolbar.frame = toolbarFrame;
            _textField.frame = textFieldFrame;
        }];
    } else {
        _toolbar.items = items;
        _toolbar.frame = toolbarFrame;
        _textField.frame = textFieldFrame;
    }
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
    [self addToolbarButtonWithTitle:title target:self action:@selector(toolbarItemTapped:)];
}

- (void)addToolbarButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action
{
    UIBarButtonItem *item = [[[UIBarButtonItem alloc] initWithTitle:title
                                                              style:UIBarButtonItemStyleBordered
                                                             target:target
                                                             action:action] autorelease];
    // TODO: make these into UIButtons so we don't have to guess the font size
    item.width = [title sizeWithFont:[UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]]].width + 2 * TOOLBAR_BUTTON_PADDING;
    [self addToolbarButton:item animated:NO];
}

- (void)addToolbarButtonWithImage:(UIImage *)image {
    [self addToolbarButtonWithImage:image target:self action:@selector(toolbarItemTapped:)];
}

- (void)addToolbarButtonWithImage:(UIImage *)image target:(id)target action:(SEL)action
{
    UIBarButtonItem *item = [[[UIBarButtonItem alloc] initWithImage:image
                                                              style:UIBarButtonItemStyleBordered
                                                             target:target
                                                             action:action] autorelease];
    // TODO: make these into UIButtons
    item.width = image.size.width + 2 * TOOLBAR_BUTTON_PADDING;
    [self addToolbarButton:item animated:NO];
}

- (void)toolbarItemTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(toolbarItemTapped:)]
        && [sender isKindOfClass:[UIBarButtonItem class]]
    ) {
        [self.delegate toolbarItemTapped:(UIBarButtonItem *)sender];
    }
}

- (UIColor *)tintColor {
    return _toolbarTintColor;
}

- (void)setTintColor:(UIColor *)color {
    [_toolbarTintColor release];
    _toolbarTintColor = [color retain];
    
    _toolbar.tintColor = _toolbarTintColor;
}

- (BOOL)showsCancelButton {
    return _cancelButton != nil;
}

- (void)setShowsCancelButton:(BOOL)showsCancelButton {
    [self setShowsCancelButton:showsCancelButton animated:NO];
}

- (void)setShowsCancelButton:(BOOL)showsCancelButton animated:(BOOL)animated {
    if (showsCancelButton == [self showsCancelButton]) {
        return;
    }
    
    if (showsCancelButton) {
        if (!_cancelButton) {
            // we can't easily estimate the size of a UIBarButtonSystemItem,
            // so we have to create our own and and provide our own width
            UIButton *innerButton = [UIButton buttonWithType:UIButtonTypeCustom];
            UIImage *image = [UIImage imageWithPathName:@"common/generic-button-background"];
            UIImage *pressedImage = [UIImage imageWithPathName:@"common/generic-button-background-pressed"];
            NSString *cancelString = NSLocalizedString(@"Cancel", @"search bar cancel button");
            innerButton.titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]];
            CGSize size = [cancelString sizeWithFont:innerButton.titleLabel.font];
            innerButton.frame = CGRectMake(0, 0,
                                           size.width + TOOLBAR_BUTTON_PADDING * 2,
                                           image.size.height);
            [innerButton setBackgroundImage:[image stretchableImageWithLeftCapWidth:10 topCapHeight:0]
                                   forState:UIControlStateNormal];
            [innerButton setBackgroundImage:[pressedImage stretchableImageWithLeftCapWidth:10 topCapHeight:0]
                                   forState:UIControlStateHighlighted];
            [innerButton setTitle:cancelString forState:UIControlStateNormal];
            [innerButton addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            
            _cancelButton = [[UIBarButtonItem alloc] initWithCustomView:innerButton];
            _cancelButton.width = innerButton.frame.size.width;
        }
        
        if (_toolbar.items.count) {
            _hiddenToolbarItems = [_toolbar.items copy];
        }
        [self setToolbarItems:[NSArray arrayWithObject:_cancelButton] animated:animated];
        
    } else {
        [self setToolbarItems:_hiddenToolbarItems animated:animated];
        if (_hiddenToolbarItems) {
            [_hiddenToolbarItems release];
            _hiddenToolbarItems = nil;
        }
        
        if (_cancelButton) {
            [_cancelButton release];
            _cancelButton = nil;
        }
    }
}

#pragma mark Text field delegation

// sent by _bookmarkButton
- (void)searchBarBookmarkButtonClicked:(id)sender {
    if ([self.delegate respondsToSelector:@selector(searchBarBookmarkButtonClicked:)]) {
        [self.delegate searchBarBookmarkButtonClicked:self];
    }
}

- (void)cancelButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(searchBarCancelButtonClicked:)]) {
        [self.delegate searchBarCancelButtonClicked:self];
    }
    [self showToolbarAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([self.delegate respondsToSelector:@selector(searchBarSearchButtonClicked:)]) {
        [self.delegate searchBarSearchButtonClicked:self];
    }
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ([self.delegate respondsToSelector:@selector(searchBarTextDidBeginEditing:)]) {
        [self.delegate searchBarTextDidBeginEditing:self];
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // TODO: decide if we need something here
    [textField setNeedsLayout];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // TODO: this isn't quite accurate, see if we need to do more
    NSMutableString *text = [[textField.text mutableCopy] autorelease];
    [text replaceCharactersInRange:range withString:string];
    if ([self.delegate respondsToSelector:@selector(searchBar:textDidChange:)]) {
        [self.delegate searchBar:self textDidChange:text];
    }
    return YES;
}

- (BOOL)becomeFirstResponder {
    if ([_textField becomeFirstResponder]) {
        [self setShowsCancelButton:YES animated:YES];
    }
    return YES;
}

- (BOOL)resignFirstResponder {
    if ([_textField resignFirstResponder]) {
        [self setShowsCancelButton:NO animated:YES];
    }
    return YES;
}

#pragma mark Text field properties

- (UITextAutocapitalizationType) autocapitalizationType {
    return _textField.autocapitalizationType;
}

- (void)setAutocapitalizationType:(UITextAutocapitalizationType)type {
    _textField.autocapitalizationType = type;
}

- (UITextAutocorrectionType) autocorrectionType {
    return _textField.autocapitalizationType;
}

- (void)setAutocorrectionType:(UITextAutocorrectionType)type {
    _textField.autocorrectionType = type;
}

- (UIKeyboardType)keyboardType {
    return _textField.keyboardType;
}

- (void)setKeyboardType:(UIKeyboardType)type {
    _textField.keyboardType = type;
}

- (UIKeyboardAppearance)keyboardAppearance {
    return _textField.keyboardAppearance;
}

- (void)setKeyboardAppearance:(UIKeyboardAppearance)keyboardAppearance {
    _textField.keyboardAppearance = keyboardAppearance;
}

- (NSString *)placeholder {
    return _textField.placeholder;
}

- (void)setPlaceholder:(NSString *)placeholder {
    _textField.placeholder = placeholder;
}

- (NSString *)text {
    DLog(@"textfield: %@", _textField.text);
    return _textField.text;
}

- (void)setText:(NSString *)text {
    _textField.text = text;
}

- (UIFont *)font {
    return _textField.font;
}

- (void)setFont:(UIFont *)font {
    _textField.font = font;
}

- (UIColor *)textColor {
    return _textField.textColor;
}

- (void)setTextColor:(UIColor *)textColor {
    _textField.textColor = textColor;
}

- (BOOL)showsBookmarkButton {
    return _bookmarkButton != nil;
}

- (void)setShowsBookmarkButton:(BOOL)shows {
    if (shows) {
        if (!_bookmarkButton) {
            _bookmarkButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
            UIImage *image = [UIImage imageWithPathName:@"common/searchfield_star"];
            [_bookmarkButton setImage:image forState:UIControlStateNormal];
            _bookmarkButton.frame = CGRectMake(0, 0, image.size.width, image.size.height);
            [_bookmarkButton addTarget:self
                                action:@selector(searchBarBookmarkButtonClicked:)
                      forControlEvents:UIControlEventTouchUpInside];
            _textField.rightView = _bookmarkButton;
        }
        
    } else if (_bookmarkButton) {
        if (_textField.rightView == _bookmarkButton) {
            _textField.rightView = nil;
        }
        [_bookmarkButton release];
        _bookmarkButton = nil;
    }
}
                     
#pragma mark Segmented control properties

- (NSArray *)scopeButtonTitles {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[_scopeButtonControl numberOfSegments]];
    for (int i = 0; i < [_scopeButtonControl numberOfSegments]; i++) {
        [array addObject:[_scopeButtonControl titleForSegmentAtIndex:i]];
    }
    return [[array copy] autorelease];
}

- (void)setScopeButtonTitles:(NSArray *)titles {
    [_scopeButtonControl removeAllSegments];
    for (int i = 0; i < titles.count; i++) {
        id foreground = [titles objectAtIndex:i];
        if ([foreground isKindOfClass:[NSString class]]) {
            [_scopeButtonControl insertSegmentWithTitle:foreground atIndex:[_scopeButtonControl numberOfSegments] animated:NO];
        } else if ([foreground isKindOfClass:[UIImage class]]) {
            [_scopeButtonControl insertSegmentWithImage:foreground atIndex:[_scopeButtonControl numberOfSegments] animated:NO];
        }
    }
}

- (NSInteger)selectedScopeButtonIndex {
    return _scopeButtonControl.selectedSegmentIndex;
}

- (void)setSelectedScopeButtonIndex:(NSInteger)index {
    [_scopeButtonControl setSelectedSegmentIndex:index];
    
    if ([self.delegate respondsToSelector:@selector(searchBar:selectedScopeButtonIndexDidChange:)]) {
        [self.delegate searchBar:self selectedScopeButtonIndexDidChange:index];
    }
}

- (BOOL)showsScopeBar {
    return _scopeButtonControl != nil;
}

- (void)setShowsScopeBar:(BOOL)shows {
    if (shows) {
        // TODO: make sure this doesn't mess up drop shadow
        if (!_scopeButtonControl) {
            CGRect frame = self.frame;
            frame.origin.x = 0;
            frame.origin.y = self.frame.size.height;
            _scopeButtonControl = [[UISegmentedControl alloc] initWithFrame:frame];
            frame = self.frame;
            frame.size.height += _scopeButtonControl.frame.size.height;
            self.frame = frame;
            [self addSubview:_scopeButtonControl];
        }
        
    } else if (_scopeButtonControl) {
        [_scopeButtonControl removeFromSuperview];
        [_scopeButtonControl release];
        _scopeButtonControl = nil;

        CGRect frame = self.frame;
        frame.size.height = SEARCH_BAR_HEIGHT;
        self.frame = frame;
    }
}

@end
