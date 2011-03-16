#import "ExternalURLModule.h"
#import "Foundation+KGOAdditions.h"

@implementation ExternalURLModule

@synthesize url;

- (id)initWithDictionary:(NSDictionary *)moduleDict {
    self = [super initWithDictionary:moduleDict];
    if (self) {
        self.url = [moduleDict stringForKey:@"url" nilIfEmpty:YES];
    }
    return self;
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    
    NSURL *externalURL = [NSURL URLWithString:self.url];
    if ([[UIApplication sharedApplication] canOpenURL:externalURL]) {
        [[UIApplication sharedApplication] openURL:externalURL];
    }

    return nil;
}

@end
