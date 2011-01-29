#import "CampusMapToolbar.h"


@implementation CampusMapToolbar


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
	UIImage *image = [UIImage imageNamed:@"global/toolbar-background.png"];
	[image drawInRect:rect];
}


- (void)dealloc {
    [super dealloc];
}


@end
