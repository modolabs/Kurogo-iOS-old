#import "KGOTabbedControl.h"
#import "Foundation+KGOAdditions.h"
#import "UIKit+KGOAdditions.h"

@interface KGOTabbedControl (Private)

- (CGSize)foregroundSizeForTabAtIndex:(NSUInteger)tabIndex;
- (NSInteger)tabIndexAtLocation:(CGPoint)point;
- (void)touchUpOutside:(id)sender forEvent:(UIEvent *)event;
- (void)touchDown:(id)sender forEvent:(UIEvent *)event;
- (void)touchUpInside:(id)sender forEvent:(UIEvent *)event;
- (UIColor *)textColorForState:(KGOTabState)state;
- (UIImage *)imageForState:(KGOTabState)state;
- (void)didInsertTabAtIndex:(NSInteger)index animated:(BOOL)animated;

@end

@implementation KGOTabbedControl

@synthesize tabPadding, tabSpacing, tabFont;

// for initializing from nib files
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _tabs = [[NSMutableArray alloc] init];
        _selectedTabIndex = KGOTabbedControlNoTab;
        _pressedTabIndex = KGOTabbedControlNoTab;
        
        self.tabSpacing = 10;
        self.tabPadding = 5;
        // TODO: use config for font
        self.tabFont = [UIFont boldSystemFontOfSize:15];
        
		[self addTarget:self action:@selector(touchUpInside:forEvent:) forControlEvents:UIControlEventTouchUpInside];
		[self addTarget:self action:@selector(touchDown:forEvent:) forControlEvents:UIControlEventTouchDown];
		[self addTarget:self action:@selector(touchUpOutside:forEvent:) forControlEvents:UIControlEventTouchUpOutside];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _tabs = [[NSMutableArray alloc] init];
        _selectedTabIndex = KGOTabbedControlNoTab;
        _pressedTabIndex = KGOTabbedControlNoTab;
        
        self.tabSpacing = 10;
        self.tabPadding = 5;
        // TODO: use config for font
        self.tabFont = [UIFont boldSystemFontOfSize:15];
        
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
		[self addTarget:self action:@selector(touchUpInside:forEvent:) forControlEvents:UIControlEventTouchUpInside];
		[self addTarget:self action:@selector(touchDown:forEvent:) forControlEvents:UIControlEventTouchDown];
		[self addTarget:self action:@selector(touchUpOutside:forEvent:) forControlEvents:UIControlEventTouchUpOutside];
    }
    return self;
}

- (id)initWithItems:(NSArray *)items {
    self = [super init];
    if (self) {
        _tabs = [[NSMutableArray alloc] initWithCapacity:items.count];
        _selectedTabIndex = KGOTabbedControlNoTab;
        _pressedTabIndex = KGOTabbedControlNoTab;
        
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
		[self addTarget:self action:@selector(touchUpInside:forEvent:) forControlEvents:UIControlEventTouchUpInside];
		[self addTarget:self action:@selector(touchDown:forEvent:) forControlEvents:UIControlEventTouchDown];
		[self addTarget:self action:@selector(touchUpOutside:forEvent:) forControlEvents:UIControlEventTouchUpOutside];
    }
    return self;
}

- (NSUInteger)numberOfTabs {
    return [_tabs count];
}

- (void)setSelectedTabIndex:(NSInteger)index {
    if (_selectedTabIndex != KGOTabbedControlNoTab) {
        _tabStates[_selectedTabIndex] = KGOTabStateInactive;
    }
    
    // TODO: check enabled states
    if (index == KGOTabbedControlNoTab || (index >= 0 && index < self.numberOfTabs)) {
        _selectedTabIndex = index;
        if (index != KGOTabbedControlNoTab) {
            _tabStates[_selectedTabIndex] = KGOTabStateActive;
        }
    }
}

- (NSInteger)selectedTabIndex {
    return _selectedTabIndex;
}

- (void)setPressedTabIndex:(NSInteger)index {
    if (_pressedTabIndex != KGOTabbedControlNoTab) {
        _tabStates[_pressedTabIndex] = KGOTabStateInactive;
    }
    
    // TODO: check enabled states
    if (index == KGOTabbedControlNoTab || (index >= 0 && index < self.numberOfTabs)) {
        _pressedTabIndex = index;
        if (index != KGOTabbedControlNoTab) {
            _tabStates[_pressedTabIndex] = KGOTabStatePressed;
        }
    }
}

- (NSInteger)pressedTabIndex {
    return _pressedTabIndex;
}

- (void)insertTabWithImage:(UIImage *)image atIndex:(NSUInteger)index animated:(BOOL)animated {
    if (![image isKindOfClass:[UIImage class]] || index > _tabs.count) return;
    [_tabs insertObject:image atIndex:index];
    [self didInsertTabAtIndex:index animated:animated];
}

- (void)insertTabWithTitle:(NSString *)title atIndex:(NSUInteger)index animated:(BOOL)animated {
    if (![title isKindOfClass:[NSString class]] || index > _tabs.count) return;
    [_tabs insertObject:title atIndex:index];
    [self didInsertTabAtIndex:index animated:animated];
}

- (void)didInsertTabAtIndex:(NSInteger)index animated:(BOOL)animated {
    CGFloat *newTabWidths = malloc(_tabs.count * sizeof(CGFloat));
    KGOTabState *newTabStates = malloc(_tabs.count * sizeof(KGOTabState));
    for (NSUInteger i = 0; i < _tabs.count; i++) {
        if (i < index) {
            newTabWidths[i] = _tabMinWidths[i];
            newTabStates[i] = _tabStates[i];
        } else if (i == index) {
            newTabWidths[i] = 0;
            newTabStates[i] = KGOTabStateInactive;
        } else {
            newTabWidths[i] = _tabMinWidths[i-1];
            newTabStates[i] = _tabStates[i-1];
        }
    }
    if (_tabMinWidths) {
        free(_tabMinWidths);
    }
    _tabMinWidths = newTabWidths;
    if (_tabStates) {
        free(_tabStates);
    }
    _tabStates = newTabStates;
    
    // TODO: don't ignore animated parameter
    [self setNeedsDisplay];
}

- (BOOL)isEnabledForTabAtIndex:(NSUInteger)index {
    // TODO: implement
    return YES;
}

- (void)removeAllTabs {
    [_tabs removeAllObjects];

    if (_tabMinWidths) {
        free(_tabMinWidths);
        _tabMinWidths = NULL;
    }
    
    if (_tabStates) {
        free(_tabStates);
        _tabStates = NULL;
    }
}

- (void)removeTabAtIndex:(NSUInteger)index animated:(BOOL)animated {
    if (index >= _tabs.count) return;
    
    // TODO: don't ignore animated parameter
    
    
    [_tabs removeObjectAtIndex:index];
    CGFloat *newTabWidths = NULL;
    KGOTabState *newTabStates = NULL;
    if (_tabs.count) {
        newTabWidths = malloc(_tabs.count * sizeof(CGFloat));
        newTabStates = malloc(_tabs.count * sizeof(KGOTabState));
        for (NSUInteger i = 0; i < _tabs.count; i++) {
            if (i < index) {
                newTabWidths[i] = _tabMinWidths[i];
                newTabStates[i] = _tabStates[i];
            } else {
                newTabWidths[i] = _tabMinWidths[i+1];
                newTabStates[i] = _tabStates[i+1];
            }
        }
    }
    free(_tabMinWidths);
    _tabMinWidths = newTabWidths;
    free(_tabStates);
    _tabStates = newTabStates;
}

- (void)setEnabled:(BOOL)enabled forTabAtIndex:(NSUInteger)index {
}

- (void)setImage:(UIImage *)image forTabAtIndex:(NSUInteger)index {
    if (index < self.numberOfTabs && [image isKindOfClass:[UIImage class]]) {
        [_tabs removeObjectAtIndex:index];
        [_tabs insertObject:image atIndex:index];
    }
}

- (void)setTitle:(NSString *)title forTabAtIndex:(NSUInteger)index {
    if (index < self.numberOfTabs && [title isKindOfClass:[NSString class]]) {
        [_tabs removeObjectAtIndex:index];
        [_tabs insertObject:title atIndex:index];
    }
}

- (void)setMinimumWidth:(CGFloat)width forTabAtIndex:(NSUInteger)index {
    if (index < self.numberOfTabs) {
        _tabMinWidths[index] = width;
    }
}

- (NSString *)titleForTabAtIndex:(NSUInteger)index {
    if (index < self.numberOfTabs) {
        return [_tabs stringAtIndex:index];
    }
    return nil;
}

- (UIImage *)imageForTabAtIndex:(NSUInteger)index {
    if (index < self.numberOfTabs) {
        id image = [_tabs objectAtIndex:index];
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

- (UIImage *)imageForState:(KGOTabState)state {
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
            return [UIColor blackColor];
        case KGOTabStateActive:
            return [UIColor blackColor];
        case KGOTabStatePressed:
            return [UIColor blackColor];
        case KGOTabStateDisabled:
            return [UIColor blackColor];
        default:
            return nil;
    }
}

- (void)drawRect:(CGRect)rect {
    
	CGContextRef context =  UIGraphicsGetCurrentContext();
	CGFloat tabOffset = self.tabSpacing;

	for (int tabIndex = 0; tabIndex < _tabs.count; tabIndex++) {
		id foreground = [_tabs objectAtIndex:tabIndex];
        CGSize size = [self foregroundSizeForTabAtIndex:tabIndex];
        KGOTabState state = _tabStates[tabIndex];
        UIImage *tabBackground = [self imageForState:state];
        CGRect tabRect = CGRectMake(tabOffset, 0, fmaxf(size.width + self.tabPadding * 2, _tabMinWidths[tabIndex]), self.frame.size.height);
        CGRect foregroundRect = CGRectMake(tabOffset + floor((tabRect.size.width - size.width) / 2),
                                           floor((tabRect.size.height - size.height) / 2), size.width, size.height);
        
        [tabBackground drawInRect:tabRect];
        
        if ([foreground isKindOfClass:[NSString class]]) {
            UIColor *textColor = [self textColorForState:state];
            CGContextSetFillColorWithColor(context, textColor.CGColor);
            [(NSString *)foreground drawInRect:foregroundRect withFont:self.tabFont];
        } else if ([foreground isKindOfClass:[UIImage class]]) {
            [(UIImage *)foreground drawInRect:foregroundRect];
        }
		// set the offset for the next tab
		tabOffset = tabRect.origin.x + tabRect.size.width + self.tabSpacing;
	}	
	
}

- (void)touchUpOutside:(id)sender forEvent:(UIEvent *)event {
    _tabStates[_pressedTabIndex] = KGOTabStateInactive;
	_pressedTabIndex = KGOTabbedControlNoTab;
	[self setNeedsDisplay];
}

- (void)touchDown:(id)sender forEvent:(UIEvent *)event {
	NSSet *touches = [event touchesForView:self];
	UITouch *touch = [touches anyObject];
	CGPoint touchLocation = [touch locationInView:self];
    self.pressedTabIndex = [self tabIndexAtLocation:touchLocation];

	[self setNeedsDisplay];
}

- (void)touchUpInside:(id)sender forEvent:(UIEvent *)event {
	NSSet *touches = [event touchesForView:self];
	UITouch *touch = [touches anyObject];
	CGPoint touchLocation = [touch locationInView:self];
    self.selectedTabIndex = [self tabIndexAtLocation:touchLocation];

    [self setNeedsDisplay];
}

- (CGSize)foregroundSizeForTabAtIndex:(NSUInteger)tabIndex {
    CGSize size = CGSizeZero;
    if (tabIndex < _tabs.count) {    
		id foreground = [_tabs objectAtIndex:tabIndex];
        
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

- (NSInteger)tabIndexAtLocation:(CGPoint)point {

    NSInteger tabIndex = KGOTabbedControlNoTab;
	CGFloat tabOffset = self.tabSpacing;

	for (int testIndex = 0; testIndex < _tabs.count; testIndex++) {
        CGSize size = [self foregroundSizeForTabAtIndex:testIndex];
        
        CGRect tabRect = CGRectMake(tabOffset, 0, fmaxf(size.width, _tabMinWidths[testIndex]), self.frame.size.height);

		if (CGRectContainsPoint(tabRect, point)) {
			tabIndex = testIndex;
		}

		// set the offset for the next tab
		tabOffset = tabRect.origin.x + tabRect.size.width + self.tabSpacing;
	}
    
    return tabIndex;
}

- (void)dealloc {
    [_tabs release];
    if (_tabMinWidths) {
        free(_tabMinWidths);
    }
    if (_tabStates) {
        free(_tabStates);
    }
    [super dealloc];
}

@end

