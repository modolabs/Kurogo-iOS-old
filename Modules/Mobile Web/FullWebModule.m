#import "FullWebModule.h"

@implementation FullWebModule

- (id) init {
    self = [super init];
    if (self != nil) {
        //self.tag = MobileWebTag;
        self.shortName = @"harvard.edu";
        self.longName = @"harvard.edu";
        //self.iconName = @"full-website";
        //self.canBecomeDefault = FALSE;
    }
    return self;
}

- (void)willBecomeVisible {
    // TODO: add this string to config
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSURL URLWithString:@"http://www.harvard.edu/?fullsite=yes"]]];
}

@end
