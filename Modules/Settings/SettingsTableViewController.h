#import <UIKit/UIKit.h>
#import "KGOModule.h"


@interface SettingsTableViewController : UITableViewController {
    
    NSArray *_settingKeys;
    NSDictionary *_availableUserSettings;
    NSDictionary *_setUserSettings;

}

@end
