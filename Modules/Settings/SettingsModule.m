#import "SettingsModule.h"
#import "SettingsTableViewController.h"

@implementation SettingsModule

- (UIViewController *)moduleHomeScreenWithParams:(NSDictionary *)args {
    SettingsTableViewController *vc = [[[SettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
    return vc;
}

@end
