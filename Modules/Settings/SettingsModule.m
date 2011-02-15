#import "SettingsModule.h"
#import "SettingsTableViewController.h"

@implementation SettingsModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [[[SettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
    }
    return vc;
}

@end
