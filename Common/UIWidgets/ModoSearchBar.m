/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import "ModoSearchBar.h"
#import "MITUIConstants.h"

@implementation ModoSearchBar

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.tintColor = SEARCH_BAR_TINT_COLOR;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    UIImage *backgroundImage = [UIImage imageNamed:@"global/searchbar-background.png"];
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
    
    NSInteger viewIndex = 0;
    for (UIView *aView in self.subviews) {
        if ([aView isKindOfClass:[UITextField class]]) {
            break;
        }
        viewIndex++;
    }
    
    [self insertSubview:backgroundView atIndex:viewIndex];
}

- (void)dealloc {
    [super dealloc];
}

- (void)addDropShadow {
    NSInteger dropShadowTag = 6372;
    UIView *superview = [self superview];
    UIView *view = [superview viewWithTag:dropShadowTag];
    if (view) {
        [view removeFromSuperview];
    }
    
    UIImageView *dropShadow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"global/bar-drop-shadow.png"]];
    dropShadow.frame = CGRectMake(0, self.frame.size.height, dropShadow.frame.size.width, dropShadow.frame.size.height);
    dropShadow.tag = dropShadowTag;
    [superview addSubview:dropShadow];
    [dropShadow release];
}


@end
