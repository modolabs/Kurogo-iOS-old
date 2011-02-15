#import "AboutModule.h"
#import "AboutTableViewController.h"

@implementation AboutModule

- (UIViewController *)moduleHomeScreenWithParams:(NSDictionary *)args {
    AboutTableViewController *vc = [[[AboutTableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
    return vc;
}

@end
