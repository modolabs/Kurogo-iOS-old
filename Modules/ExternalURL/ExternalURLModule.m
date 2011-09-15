#import "ExternalURLModule.h"
#import "Foundation+KGOAdditions.h"

@implementation ExternalURLModule

@synthesize url;
/*
- (id)initWithDictionary:(NSDictionary *)moduleDict {
    self = [super initWithDictionary:moduleDict];
    if (self) {
        self.url = [moduleDict nonemptyStringForKey:@"url"];
    }
    return self;
}
*/
- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    
    NSURL *externalURL = [NSURL URLWithString:self.url];
    if ([[UIApplication sharedApplication] canOpenURL:externalURL]) {
        [[UIApplication sharedApplication] openURL:externalURL];
    }

    return nil;
}

- (void)evaluateInitialiationPayload:(NSDictionary *)payload
{
    self.url = [payload nonemptyStringForKey:@"url"];
}

- (BOOL)requiresKurogoServer
{
    return NO;
}

@end
