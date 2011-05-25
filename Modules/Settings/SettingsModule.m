#import "SettingsModule.h"
#import "SettingsTableViewController.h"
#import "KGOModule.h"
#import "KGOAppDelegate.h"

@implementation SettingsModule

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
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_notificationNames release];
    [super dealloc];
}

- (NSArray *)userDefaults
{
    return [NSArray arrayWithObjects:KGOUserPreferencesKey, nil];
}

- (BOOL)requiresKurogoServer
{
    return NO;
}

@end
