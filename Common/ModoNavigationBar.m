#import "ModoNavigationBar.h"


@implementation ModoNavigationBar

@synthesize navigationBar = _navigationBar;

- (id)initWithNavigationBar:(UINavigationBar *)navigationBar {
    navigationBar.frame = CGRectMake(0, 0, 320, 44);
    if (self = [super initWithFrame:navigationBar.frame]) {
        _navigationBar = navigationBar;
        self.delegate = _navigationBar.delegate;
    }
    return self;
}

/*
- (NSArray *)items {
    return _navigationBar.items;
} 
*/

- (id<UINavigationBarDelegate>)delegate {
    return _navigationBar.delegate;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _navigationBar = self;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    self.tintColor = [UIColor blackColor]; // this is for color of buttons  
    UIImage *image = [[UIImage imageNamed:@"global/scrolltabs-background.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:0.0];
    [image drawInRect:rect];
    
    [self update];
}

- (void)update {
    self.frame = _navigationBar.frame;
    self.items = _navigationBar.items;
}

- (void)dealloc {
    [super dealloc];
}


@end
