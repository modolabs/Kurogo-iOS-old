#import <UIKit/UIKit.h>
#import "KGOModule.h"
#import "KGOTableViewController.h"

// TODO: allow modules to hook into settings
// and get rid of code dealing with custom sections

@class SettingsModule;

@interface SettingsTableViewController : KGOTableViewController {
    
    NSArray *_settingKeys;
    UIButton *_editButton;
}

- (void)settingDidChange:(NSNotification *)aNotification;
- (void)editModuleButtonPressed:(id)sender;

@end
