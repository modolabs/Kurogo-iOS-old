#import "ModoNavigationBar.h"


@implementation ModoNavigationBar

@synthesize navigationBar = _navigationBar;

- (id)initWithNavigationBar:(UINavigationBar *)navigationBar {
    //navigationBar.frame = CGRectMake(0, 0, 320, 44);
    if (self = [super initWithFrame:navigationBar.frame]) {
        self.navigationBar = navigationBar;
        //[self.navigationBar addSubview:self];
        //self.delegate = self.navigationBar.delegate;
    }
    return self;
}

/*
- (NSArray *)items {
    return _navigationBar.items;
} 
*/

- (id<UINavigationBarDelegate>)delegate {
    return self.navigationBar.delegate;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.navigationBar = self;
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
    self.frame = CGRectMake(0, 0, self.navigationBar.frame.size.width, self.navigationBar.frame.size.height);
    self.items = self.navigationBar.items;
}


- (UINavigationItem *)popNavigationItemAnimated:(BOOL)animated {
    UINavigationItem *item = [super popNavigationItemAnimated:animated];
    if (item == nil) {
        [self popNavigationItemAnimated:animated];
    }
    return item;
}

/*
- (void)pushNavigationItem:(UINavigationItem *)item animated:(BOOL)animated {
    [super pushNavigationItem:item animated:animated];
}

- (void)didAddSubview:(UIView *)subview {
    [super didAddSubview:subview];
}

- (void)willRemoveSubview:(UIView *)subview {
    [super willRemoveSubview:subview];
}
*/

- (void)dealloc {
    if (self.navigationBar.delegate != nil) { // someone else owns the nav bar
        self.navigationBar = nil;
    } else {
        [self.navigationBar release];
    }
    [super dealloc];
}

@end
