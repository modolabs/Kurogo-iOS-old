#import "KGOSegmentedControl.h"
#import "UIKit+KGOAdditions.h"
#import "KGOTheme.h"

@implementation KGOSegmentedControl

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.tabSpacing = 0;
        self.tabPadding = 2;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.tabSpacing = 0;
        self.tabPadding = 2;
    }
    return self;
}

- (id)initWithItems:(NSArray *)items
{
    self = [super initWithItems:items];
    if (self) {
        self.tabSpacing = 0;
        self.tabPadding = 2;
    }
    return self;
}

- (NSInteger)selectedSegmentIndex
{
    return [self selectedTabIndex];
}

- (void)setSelectedSegmentIndex:(NSInteger)selectedSegmentIndex
{
    [self setSelectedTabIndex:selectedSegmentIndex];
}

- (UIImage *)backgroundImageForState:(KGOTabState)state atIndex:(NSUInteger)index
{
    NSString *imagePosition = nil;
    NSString *imagePath = nil;

    if ([self numberOfSegments] == 1) {
        imagePosition = @"middle";
    } else if (index == 0) {
        imagePosition = @"left";
    } else if (index == [self numberOfSegments] - 1) {
        imagePosition = @"right";
    } else {
        imagePosition = @"middle";
    }

    if (state == KGOTabStatePressed || state == KGOTabStateActive) {
        imagePath = [NSString stringWithFormat:@"common/toolbar-segmented-%@-pressed", imagePosition];
    } else {
        imagePath = [NSString stringWithFormat:@"common/toolbar-segmented-%@", imagePosition];
    }
    
    return [[UIImage imageWithPathName:imagePath] stretchableImageWithLeftCapWidth:15.0 topCapHeight:0];
}

- (UIColor *)textColorForState:(KGOTabState)state {
    
    switch (state) {
        case KGOTabStateInactive:
            return [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyScrollTab];
        case KGOTabStateActive:
            return [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyScrollTabSelected];
        case KGOTabStatePressed:
            return [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyScrollTabSelected];
        case KGOTabStateDisabled:
            return [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyScrollTab];
        default:
            return nil;
    }
}

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents
{
    _target = target;
    _action = action;
    
    self.delegate = self;
}

- (void)tabbedControl:(KGOTabbedControl *)contol didSwitchToTabAtIndex:(NSInteger)index
{
    [_target performSelector:_action withObject:self];
}

#pragma mark unimplemented UISegmentedControl-like methods

- (BOOL)isMomentary
{
    return _momentary;
}

- (void)setMomentary:(BOOL)momentary
{
    _momentary = momentary;
}

- (void)setContentOffset:(CGSize)offset forSegmentAtIndex:(NSUInteger)segment
{
    ;
}

- (CGSize)contentOffsetForSegmentAtIndex:(NSUInteger)segment
{
    return CGSizeZero;
}

#pragma mark superclass forwarders

- (NSUInteger)numberOfSegments
{
    return [self numberOfTabs];
}

- (void)setImage:(UIImage *)image forSegmentAtIndex:(NSUInteger)segment
{
    [self setImage:image forTabAtIndex:segment];
}

- (UIImage *)imageForSegmentAtIndex:(NSUInteger)segment
{
    return [self imageForTabAtIndex:segment];
}

- (void)setTitle:(NSString *)title forSegmentAtIndex:(NSUInteger)segment
{
    [self setTitle:title forTabAtIndex:segment];
}

- (NSString *)titleForSegmentAtIndex:(NSUInteger)segment
{
    return [self titleForTabAtIndex:segment];
}

- (void)insertSegmentWithImage:(UIImage *)image atIndex:(NSUInteger)segment animated:(BOOL)animated
{
    [self insertTabWithImage:image atIndex:segment animated:animated];
}

- (void)insertSegmentWithTitle:(NSString *)title atIndex:(NSUInteger)segment animated:(BOOL)animated
{
    [self insertTabWithTitle:title atIndex:segment animated:animated];
}

- (void)removeAllSegments
{
    [self removeAllTabs];
}

- (void)removeSegmentAtIndex:(NSUInteger)segment animated:(BOOL)animated
{
    [self removeTabAtIndex:segment animated:animated];
}

- (void)setEnabled:(BOOL)enabled forSegmentAtIndex:(NSUInteger)segment
{
    [self setEnabled:enabled forTabAtIndex:segment];
}

- (BOOL)isEnabledForSegmentAtIndex:(NSUInteger)segment
{
    return [self isEnabledForTabAtIndex:segment];
}

- (void)setWidth:(CGFloat)width forSegmentAtIndex:(NSUInteger)segment
{
    [self setMinimumWidth:width forTabAtIndex:segment];
}

- (CGFloat)widthForSegmentAtIndex:(NSUInteger)segment
{
    return [self minimumWidthForTabAtIndex:segment];
}

@end
