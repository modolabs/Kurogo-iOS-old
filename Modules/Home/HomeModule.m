#import "HomeModule.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "SpringboardViewController.h"
#import "KGOHomeScreenTableViewController.h"

@implementation HomeModule

#pragma mark Navigation

- (NSArray *)registeredPageNames {
    return [NSArray arrayWithObject:LocalPathPageNameHome];
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        KGONavigationStyle style = [(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] navigationStyle];
        switch (style) {
            case KGONavigationStyleTableView:
                vc = [[[KGOHomeScreenTableViewController alloc] init] autorelease];
                break;
            case KGONavigationStyleIconGrid:
            default:
                vc = [[[SpringboardViewController alloc] init] autorelease];
                break;
        }
    }
    return vc;
}

#pragma mark Data

- (NSArray *)objectModelNames {
    return [NSArray arrayWithObject:@"RecentSearches"];
}

@end
