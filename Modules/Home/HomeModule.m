#import "HomeModule.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOSpringboardViewController.h"
#import "KGOHomeScreenTableViewController.h"
#import "KGOPortletHomeViewController.h"
#import "KGOSidebarFrameViewController.h"

@implementation HomeModule

#pragma mark Navigation

- (NSArray *)registeredPageNames {
    return [NSArray arrayWithObject:LocalPathPageNameHome];
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        KGONavigationStyle style = [KGO_SHARED_APP_DELEGATE() navigationStyle];
        switch (style) {
            case KGONavigationStyleTableView:
                vc = [[[KGOHomeScreenTableViewController alloc] init] autorelease];
                break;
            case KGONavigationStylePortlet:
                vc = [[[KGOPortletHomeViewController alloc] init] autorelease];
                break;
            case KGONavigationStyleTabletSidebar:
                vc = [[[KGOSidebarFrameViewController alloc] init] autorelease];
                break;
            case KGONavigationStyleIconGrid:
            default:
                vc = [[[KGOSpringboardViewController alloc] init] autorelease];
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
