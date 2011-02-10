#import "HomeModule.h"
#import "KGOAppDelegate.h"
#import "SpringboardViewController.h"

@implementation HomeModule

#pragma mark Navigation

- (NSArray *)registeredPageNames {
    return [NSArray arrayWithObject:LocalPathPageNameHome];
}

- (UIViewController *)moduleHomeScreenWithParams:(NSDictionary *)args {
    SpringboardViewController *vc = [[[SpringboardViewController alloc] init] autorelease];
    return vc;
}

#pragma mark Data

- (NSArray *)objectModelNames {
    return [NSArray arrayWithObject:@"RecentSearches"];
}

@end
