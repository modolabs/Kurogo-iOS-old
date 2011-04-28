#import "KGOTabbedControl.h"

// clone of UISegmentedControl based on KGOTabbedControl.
// TODO: since most of these functions are forwarders, we can probably just
// use one implementation for everything and only subclass for the backgrond
// images.

enum {
    KGOSegmentedControlNoSegment = -1   // segment index for no selected segment
};

@interface KGOSegmentedControl : KGOTabbedControl <KGOTabbedControlDelegate> {
    
    BOOL _momentary;
    id _target;
    SEL _action;
    
}

- (void)setImage:(UIImage *)image forSegmentAtIndex:(NSUInteger)segment;
- (UIImage *)imageForSegmentAtIndex:(NSUInteger)segment;
- (void)setTitle:(NSString *)title forSegmentAtIndex:(NSUInteger)segment;
- (NSString *)titleForSegmentAtIndex:(NSUInteger)segment;
- (void)insertSegmentWithImage:(UIImage *)image atIndex:(NSUInteger)segment animated:(BOOL)animated;
- (void)insertSegmentWithTitle:(NSString *)title atIndex:(NSUInteger)segment animated:(BOOL)animated;
- (void)removeAllSegments;
- (void)removeSegmentAtIndex:(NSUInteger)segment animated:(BOOL)animated;
- (void)setEnabled:(BOOL)enabled forSegmentAtIndex:(NSUInteger)segment;
- (void)setWidth:(CGFloat)width forSegmentAtIndex:(NSUInteger)segment;
- (CGFloat)widthForSegmentAtIndex:(NSUInteger)segment;
- (void)setContentOffset:(CGSize)offset forSegmentAtIndex:(NSUInteger)segment;
- (BOOL)isEnabledForSegmentAtIndex:(NSUInteger)segment;
- (CGSize)contentOffsetForSegmentAtIndex:(NSUInteger)segment;

@property(nonatomic) NSInteger selectedSegmentIndex;
@property(nonatomic, getter = isMomentary) BOOL momentary;
@property(nonatomic, readonly) NSUInteger numberOfSegments;

// fake superclass methods
- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;

// not providing an equivalent for the following
// as there is either no choice or no point:
// - segmentedControlStyle
// - tintColor

@end
