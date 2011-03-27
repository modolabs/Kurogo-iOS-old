#import "ContentModule.h"
#import "ContentTableViewController.h"

@implementation ContentModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [[[ContentTableViewController alloc] initWithStyle:UITableViewStyleGrouped moduleTag:ContentTag] autorelease];
    }
    return vc;
}

@end