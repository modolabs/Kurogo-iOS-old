#import "EmergencyModule.h"
#import "EmergencyHomeViewController.h"

NSString * const EmergencyContactsPathPageName = @"contacts";

@implementation EmergencyModule
@synthesize noticeFeedExists;
@synthesize contactsFeedExists;

- (id)initWithDictionary:(NSDictionary *)moduleDict {
    self = [super initWithDictionary:moduleDict];
    if(self) {
        // for now we hard code these settings
        noticeFeedExists = YES;
        contactsFeedExists = YES;
    }
    return self;
}

#pragma mark Search

- (BOOL)supportsFederatedSearch {
    return NO;
}

#pragma mark Data

- (NSArray *)objectModelNames {
    return [NSArray arrayWithObject:@"Emergency"];
}

#pragma mark Navigation

- (NSArray *)registeredPageNames {
    return [NSArray arrayWithObjects:LocalPathPageNameHome, EmergencyContactsPathPageName, nil];
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [[[EmergencyHomeViewController alloc] init] autorelease];
        [(EmergencyHomeViewController *)vc setModule:self];
    }   
    return vc;
}

@end

