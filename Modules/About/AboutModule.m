#import "AboutModule.h"
#import "AboutTableViewController.h"

@implementation AboutModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [[[AboutTableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
    }
    return vc;
}

@end
