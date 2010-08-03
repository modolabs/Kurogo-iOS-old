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


@end
