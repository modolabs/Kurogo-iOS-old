#import <UIKit/UIKit.h>
#import "KGOModule.h"
#import "KGOTableViewController.h"

// TODO: allow modules to hook into settings
// and get rid of code dealing with custom sections

@class SettingsModule;

@interface SettingsTableViewController : KGOTableViewController {
    
    NSArray *_settingKeys;

    UIButton *_primaryEditButton;
    BOOL _isEditingPrimary;

    UIButton *_secondaryEditButton;
    BOOL _isEditingSecondary;
    
    NSMutableDictionary *_headerViews;
}

- (void)settingDidChange:(NSNotification *)aNotification;
- (void)editModuleButtonPressed:(id)sender;

@property(nonatomic, retain) NSArray *settingKeys;

@end
