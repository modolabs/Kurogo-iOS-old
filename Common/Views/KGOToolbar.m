#import "KGOToolbar.h"
#import "KGOTheme.h"

@implementation KGOToolbar

@synthesize backgroundImage;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.backgroundImage = [[KGOTheme sharedTheme] backgroundImageForToolbar];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundImage = [[KGOTheme sharedTheme] backgroundImageForToolbar];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    if (self.backgroundImage) {
        // right-align the same background image
        CGRect adjustedRect = CGRectMake(rect.origin.x + rect.size.width - self.backgroundImage.size.width, rect.origin.y, self.backgroundImage.size.width, self.backgroundImage.size.height);
        [self.backgroundImage drawInRect:adjustedRect];
    } else {
        [super drawRect:rect];
    }
}

- (void)dealloc {
    self.backgroundImage = nil;
    [super dealloc];
}

@end