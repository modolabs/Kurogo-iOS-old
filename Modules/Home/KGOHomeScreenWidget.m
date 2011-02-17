#import "KGOHomeScreenWidget.h"


@implementation KGOHomeScreenWidget

@synthesize gravity, behavesAsIcon, overlaps;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        self.behavesAsIcon = YES;
        self.overlaps = NO;
    }
    return self;
}

- (void)tapped {
    ;
}

- (void)dealloc {
    [super dealloc];
}


@end
