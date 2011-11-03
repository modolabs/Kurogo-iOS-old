#import "KGOTabbedControl.h"
#import "Foundation+KGOAdditions.h"
#import "UIKit+KGOAdditions.h"
#import "KGOTheme.h"

@interface KGOTabbedControl (Private)

- (CGSize)foregroundSizeForTabAtIndex:(NSUInteger)tabIndex;
- (UIColor *)textColorForState:(KGOTabState)state;
- (void)didInsertTabAtIndex:(NSInteger)index animated:(BOOL)animated;
- (UIButton *)buttonForTab;
- (void)setButtonState:(KGOTabState)state atIndex:(NSInteger)index;

@end

@implementation KGOTabbedControl

@synthesize tabPadding, tabSpacing, tabFont, delegate;

// for initializing from nib files
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _tabs = [[NSMutableArray alloc] init];
        _tabContents = [[NSMutableArray alloc] init];
        _selectedTabIndex = NSNotFound;
        
        self.tabSpacing = 10;
        self.tabPadding = 5;
        // TODO: use config for font
        self.tabFont = [UIFont boldSystemFontOfSize:15];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _tabs = [[NSMutableArray alloc] init];
        _tabContents = [[NSMutableArray alloc] init];
        _selectedTabIndex = NSNotFound;
        
        self.tabSpacing = 10;
        self.tabPadding = 5;
        // TODO: use config for font
        self.tabFont = [UIFont boldSystemFontOfSize:15];
        
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (id)initWithItems:(NSArray *)items {
    self = [super init];
    if (self) {
        _tabs = [[NSMutableArray alloc] initWithCapacity:items.count];
        _tabContents = [[NSMutableArray alloc] initWithCapacity:items.count];
        _selectedTabIndex = NSNotFound;
        
        for (id item in items) {
            if ([item isKindOfClass:[NSString class]]) {
                [self insertTabWithTitle:item atIndex:_tabs.count animated:NO];
            } else if ([item isKindOfClass:[UIImage class]]) {
                [self insertTabWithImage:item atIndex:_tabs.count animated:NO];
            }
        }
        
        self.tabSpacing = 10;
        self.tabPadding = 5;
        // TODO: use config for font
        self.tabFont = [UIFont boldSystemFontOfSize:15];

        self.opaque = NO;
    }
    return self;
}

- (NSUInteger)numberOfTabs {
    return [_tabs count];
}

- (void)setSelectedTabIndex:(NSInteger)index {
    if (index != _selectedTabIndex) {
        if (_selectedTabIndex != NSNotFound) {
            [self setButtonState:KGOTabStateInactive atIndex:_selectedTabIndex];
        }
        
        _selectedTabIndex = index;
        if (_selectedTabIndex != NSNotFound) {
            [self setButtonState:KGOTabStateActive atIndex:_selectedTabIndex];
        }
    }
}

- (NSInteger)selectedTabIndex {
    return _selectedTabIndex;
}

- (void)insertTabWithImage:(UIImage *)image atIndex:(NSUInteger)index animated:(BOOL)animated {
    if (![image isKindOfClass:[UIImage class]] || index > _tabContents.count) return;
    [_tabContents insertObject:image atIndex:index];

    UIButton *button = [self buttonForTab];
    [button setImage:image forState:UIControlStateNormal];
    [_tabs insertObject:button atIndex:index];

    [self didInsertTabAtIndex:index animated:animated];
}

- (void)insertTabWithTitle:(NSString *)title atIndex:(NSUInteger)index animated:(BOOL)animated {
    if (![title isKindOfClass:[NSString class]] || index > _tabContents.count) return;
    [_tabContents insertObject:title atIndex:index];

    UIButton *button = [self buttonForTab];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateHighlighted];
    [_tabs insertObject:button atIndex:index];

    [self didInsertTabAtIndex:index animated:animated];
}

- (UIButton *)buttonForTab {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitleColor:[self textColorForState:KGOTabStateInactive] forState:UIControlStateNormal];
    [button setTitleColor:[self textColorForState:KGOTabStatePressed] forState:UIControlStateHighlighted];
    [button addTarget:self action:@selector(didSelectTab:) forControlEvents:UIControlEventTouchUpInside];
    button.titleLabel.font = self.tabFont;
    return button;
}

- (void)didInsertTabAtIndex:(NSInteger)index animated:(BOOL)animated
{
    CGFloat *newTabWidths = malloc(_tabs.count * sizeof(CGFloat));
    for (NSUInteger i = 0; i < _tabs.count; i++) {
        if (i < index) {
            newTabWidths[i] = _tabMinWidths[i];
        } else if (i == index) {
            newTabWidths[i] = 0;
        } else {
            newTabWidths[i] = _tabMinWidths[i-1];
        }
    }
    if (_tabMinWidths) {
        free(_tabMinWidths);
    }
    _tabMinWidths = newTabWidths;
}

- (BOOL)isEnabledForTabAtIndex:(NSUInteger)index {
    // TODO: implement
    return YES;
}

- (void)removeAllTabs {
    [_tabs removeAllObjects];
    [_tabContents removeAllObjects];

    if (_tabMinWidths) {
        free(_tabMinWidths);
        _tabMinWidths = NULL;
    }
}

- (void)removeTabAtIndex:(NSUInteger)index animated:(BOOL)animated {
    if (index >= _tabs.count) return;
    
    // TODO: don't ignore animated parameter
    
    [_tabContents removeObjectAtIndex:index];
    [_tabs removeObjectAtIndex:index];
    CGFloat *newTabWidths = NULL;
    if (_tabs.count) {
        newTabWidths = malloc(_tabs.count * sizeof(CGFloat));
        for (NSUInteger i = 0; i < _tabs.count; i++) {
            if (i < index) {
                newTabWidths[i] = _tabMinWidths[i];
            } else {
                newTabWidths[i] = _tabMinWidths[i+1];
            }
        }
    }
    free(_tabMinWidths);
    _tabMinWidths = newTabWidths;
}

- (void)setEnabled:(BOOL)enabled forTabAtIndex:(NSUInteger)index {
}

- (void)setImage:(UIImage *)image forTabAtIndex:(NSUInteger)index {
    if (index < self.numberOfTabs && [image isKindOfClass:[UIImage class]]) {
        [_tabContents removeObjectAtIndex:index];
        [_tabContents insertObject:image atIndex:index];
    }
}

- (void)setTitle:(NSString *)title forTabAtIndex:(NSUInteger)index {
    if (index < self.numberOfTabs && [title isKindOfClass:[NSString class]]) {
        [_tabContents removeObjectAtIndex:index];
        [_tabContents insertObject:title atIndex:index];
    }
}

- (void)setMinimumWidth:(CGFloat)width forTabAtIndex:(NSUInteger)index {
    if (index < self.numberOfTabs) {
        _tabMinWidths[index] = width;
    }
}

- (NSString *)titleForTabAtIndex:(NSUInteger)index {
    if (index < self.numberOfTabs) {
        return [_tabContents stringAtIndex:index];
    }
    return nil;
}

- (UIImage *)imageForTabAtIndex:(NSUInteger)index {
    if (index < self.numberOfTabs) {
        id image = [_tabContents objectAtIndex:index];
        if ([image isKindOfClass:[UIImage class]]) {
            return image;
        }
    }
    return nil;
}

- (CGFloat)minimumWidthForTabAtIndex:(NSUInteger)index {
    if (index < self.numberOfTabs) {
        return _tabMinWidths[index];
    }
    return 0;
}

- (UIImage *)backgroundImageForState:(KGOTabState)state atIndex:(NSUInteger)index {
    // TODO: use config and cache these results
    
    switch (state) {
        case KGOTabStateInactive:
            return [[UIImage imageWithPathName:@"common/tab-inactive.png"] stretchableImageWithLeftCapWidth:15.0 topCapHeight:0];
        case KGOTabStateActive:
            return [[UIImage imageWithPathName:@"common/tab-active.png"] stretchableImageWithLeftCapWidth:15.0 topCapHeight:0];
        case KGOTabStatePressed:
            return [[UIImage imageWithPathName:@"common/tab-inactive-pressed.png"] stretchableImageWithLeftCapWidth:15.0 topCapHeight:0];
        case KGOTabStateDisabled:
            return [[UIImage imageWithPathName:@"common/tab-inactive.png"] stretchableImageWithLeftCapWidth:15.0 topCapHeight:0];
        default:
            return nil;
    }
}

- (UIColor *)textColorForState:(KGOTabState)state {
    // TODO: config these values
    
    switch (state) {
        case KGOTabStateInactive:
            return [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyTab];
        case KGOTabStateActive:
            return [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyTabActive];
        case KGOTabStatePressed:
            return [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyTabSelected];
        case KGOTabStateDisabled:
            return [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyTab];
        default:
            return nil;
    }
}

- (void)layoutSubviews
{
    for (UIView *aView in self.subviews) {
        if ([aView isKindOfClass:[UIButton class]]) {
            [aView removeFromSuperview];
        }
    }
    
	CGFloat tabOffset = self.tabSpacing;
	for (int tabIndex = 0; tabIndex < _tabs.count; tabIndex++) {

        if (_selectedTabIndex == tabIndex) {
            [self setButtonState:KGOTabStateActive atIndex:tabIndex];
        } else {
            [self setButtonState:KGOTabStateInactive atIndex:tabIndex];
        }
        
        UIButton *button = [_tabs objectAtIndex:tabIndex];
        
        CGSize size = [self foregroundSizeForTabAtIndex:tabIndex];
        CGRect tabRect = CGRectMake(tabOffset, 0,
                                    fmaxf(size.width + self.tabPadding * 2, _tabMinWidths[tabIndex]),
                                    self.frame.size.height);
        button.frame = tabRect;
        [self addSubview:button];

		// set the offset for the next tab
		tabOffset = tabRect.origin.x + tabRect.size.width + self.tabSpacing;
	}	
}

- (void)didSelectTab:(id)sender
{
    NSInteger index = [_tabs indexOfObject:sender];
    if (index != NSNotFound) {
        self.selectedTabIndex = index;
        [self.delegate tabbedControl:self didSwitchToTabAtIndex:index];
    }
}

- (CGSize)foregroundSizeForTabAtIndex:(NSUInteger)tabIndex {
    CGSize size = CGSizeZero;
    if (tabIndex < _tabContents.count) {    
		id foreground = [_tabContents objectAtIndex:tabIndex];
        
        if ([foreground isKindOfClass:[NSString class]]) {
            size = [(NSString *)foreground sizeWithFont:self.tabFont];
            size.width += 2 * self.tabPadding;
        } else if ([foreground isKindOfClass:[UIImage class]]) {
            size = [(UIImage *)foreground size];
            size.width += 2 * self.tabPadding;
        }
    }
    return size;
}

- (void)setButtonState:(KGOTabState)state atIndex:(NSInteger)index
{
    UIButton *button = [_tabs objectAtIndex:index];
    
    switch (state) {
        case KGOTabStateActive:
            [button setBackgroundImage:[self backgroundImageForState:KGOTabStateActive atIndex:index]
                              forState:UIControlStateNormal];
            [button setBackgroundImage:[self backgroundImageForState:KGOTabStateActive atIndex:index]
                              forState:UIControlStateHighlighted];
            [button setTitleColor:[self textColorForState:KGOTabStateActive]
                         forState:UIControlStateNormal];
            [button setTitleColor:[self textColorForState:KGOTabStateActive]
                         forState:UIControlStateHighlighted];
            break;
        case KGOTabStateInactive:
            [button setBackgroundImage:[self backgroundImageForState:KGOTabStateInactive atIndex:index]
                              forState:UIControlStateNormal];
            [button setBackgroundImage:[self backgroundImageForState:KGOTabStatePressed atIndex:index]
                              forState:UIControlStateHighlighted];
            [button setTitleColor:[self textColorForState:KGOTabStateInactive]
                         forState:UIControlStateNormal];
            [button setTitleColor:[self textColorForState:KGOTabStatePressed]
                         forState:UIControlStateHighlighted];
            button;
        case KGOTabStateDisabled:
            [button setBackgroundImage:[self backgroundImageForState:KGOTabStateDisabled atIndex:index]
                              forState:UIControlStateNormal];
            [button setBackgroundImage:[self backgroundImageForState:KGOTabStateDisabled atIndex:index]
                              forState:UIControlStateHighlighted];
            [button setTitleColor:[self textColorForState:KGOTabStateDisabled]
                         forState:UIControlStateNormal];
            [button setTitleColor:[self textColorForState:KGOTabStateDisabled]
                         forState:UIControlStateHighlighted];
            break;
        default:
            // no separate state for pressed
            break;
    }
}

- (void)dealloc {
    [_tabs release];
    [_tabContents release];
    if (_tabMinWidths) {
        free(_tabMinWidths);
    }
    [super dealloc];
}

@end

