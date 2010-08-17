#import "MobileWebModule.h"

@implementation MobileWebModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = MobileWebTag;
        self.shortName = @"harvard.edu";
        self.longName = @"harvard.edu";
        self.iconName = @"full-website";
        self.canBecomeDefault = FALSE;
    }
    return self;
}

- (void)willAppear {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/", MITMobileWebDomainString]]];
}

@end
