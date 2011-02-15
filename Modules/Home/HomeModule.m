#import "HomeModule.h"
#import "KGOAppDelegate.h"
#import "SpringboardViewController.h"

@implementation HomeModule

#pragma mark Navigation

- (NSArray *)registeredPageNames {
    return [NSArray arrayWithObject:LocalPathPageNameHome];
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [[[SpringboardViewController alloc] init] autorelease];
    }
    return vc;
}

#pragma mark Data

- (NSArray *)objectModelNames {
    return [NSArray arrayWithObject:@"RecentSearches"];
}

@end
