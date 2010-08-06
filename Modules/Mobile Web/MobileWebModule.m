#import "MobileWebModule.h"

@implementation MobileWebModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = MobileWebTag;
        self.shortName = @"Full Website";
        self.longName = @"Full Website";
        self.iconName = @"full-website";
        self.canBecomeDefault = FALSE;
    }
    return self;
}

- (void)willAppear {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/", MITMobileWebDomainString]]];
}

@end
