#import "SettingsModule.h"
#import "SettingsTableViewController.h"
#import "KGOModule.h"
#import "KGOAppDelegate.h"

@implementation SettingsModule

- (void)launch
{
    [super launch];
    
    if (!_notificationNames) {
        _notificationNames = [[NSMutableSet alloc] init];
        
        for (KGOModule *aModule in [KGO_SHARED_APP_DELEGATE() modules]) {
            NSArray *names = [aModule applicationStateNotificationNames];
            if (names) {
                [_notificationNames addObjectsFromArray:names];
            }
        }
    }
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        SettingsTableViewController *settingsVC = [[[SettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
        settingsVC.title = self.longName;
        
        for (NSString *notificationName in _notificationNames) {
            [[NSNotificationCenter defaultCenter] addObserver:settingsVC
                                                     selector:@selector(settingDidChange:)
                                                         name:notificationName
                                                       object:nil];
        }
        vc = settingsVC;
    }
    return vc;
}

- (void)dealloc
{
    [_notificationNames release];
    [super dealloc];
}

@end
