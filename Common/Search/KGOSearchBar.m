#import "KGOSearchBar.h"
#import "KGOTheme.h"

@implementation KGOSearchBar

@synthesize backgroundImage, dropShadowImage;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        UIColor *color = [[KGOTheme sharedTheme] backgroundColorForSearchBar];
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
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    // sad way to use a background image for a search bar
    if (self.backgroundImage) {
        backgroundView = [[UIImageView alloc] initWithImage:self.backgroundImage];
        NSInteger viewIndex = 0;
        for (UIView *aView in self.subviews) {
            if ([aView isKindOfClass:[UITextField class]]) {
                break;
            }
            viewIndex++;
        }
        [self insertSubview:backgroundView atIndex:viewIndex];
    }
    
    if (self.dropShadowImage) {
        self.clipsToBounds = NO;
        dropShadow = [[UIImageView alloc] initWithImage:self.dropShadowImage];
        dropShadow.frame = CGRectMake(0, self.frame.size.height, dropShadow.frame.size.width, dropShadow.frame.size.height);
        [self addSubview:dropShadow];
    }
}

- (void)setNeedsDisplay {
    [super setNeedsDisplay];
    if (self.backgroundImage && backgroundView) {
        [backgroundView removeFromSuperview];
        [backgroundView release];
        backgroundView = nil;
    }
    if (self.dropShadowImage && dropShadow) {
        [dropShadow removeFromSuperview];
        [dropShadow release];
        dropShadow = nil;
    }
}

- (void)dealloc {
    self.backgroundImage = nil;
    self.dropShadowImage = nil;
    [backgroundView release];
    [dropShadow release];
    [super dealloc];
}


@end
