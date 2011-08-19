#import "SettingsTableViewController.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOModule.h"
#import "KGOTheme.h"
#import "KGORequestManager.h"
#import "KGOSocialMediaController.h"
#import "UIKit+KGOAdditions.h"
#import "Foundation+KGOAdditions.h"

#import "KGOUserSettingsManager.h"
#import "KGOUserSetting.h"

@implementation SettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _settingKeys = [[[KGOUserSettingsManager sharedManager] settingsKeys] retain];
}

- (void)viewWillAppear:(BOOL)animated
{
    if ([self isViewLoaded]) {
        [self reloadDataForTableView:self.tableView];
    }
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)dealloc {
    [_settingKeys release];
    [super dealloc];
}

- (void)settingDidChange:(NSNotification *)aNotification
{
    [self reloadDataForTableView:self.tableView];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = _settingKeys.count;
    // TODO: need better way to determine if login is part of the app
    if ([[KGORequestManager sharedManager] isUserLoggedIn]) {
        count += 1;
    }
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger settingsSection = section;
    if ([[KGORequestManager sharedManager] isUserLoggedIn]) {
        if (settingsSection == 0) {
            return 1;
        } else {
            settingsSection--;
        }
    }
    
    NSString *key = [_settingKeys objectAtIndex:settingsSection];
    KGOUserSetting *setting = [[KGOUserSettingsManager sharedManager] settingForKey:key];
    if ([key isEqualToString:@"Modules"]) {
        // special case
        NSArray *items = [setting.defaultValue objectForKey:@"items"];
        return items.count;
        
    } else if (!setting.unrestricted) {
        return setting.options.count;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSInteger settingsSection = section;
    if ([[KGORequestManager sharedManager] isUserLoggedIn]) {
        if (settingsSection == 0) {
            return NSLocalizedString(@"Login", @"title of login section in settings");
        } else {
            settingsSection--;
        }
    }
    
    NSString *key = [_settingKeys objectAtIndex:settingsSection];
    KGOUserSetting *setting = [[KGOUserSettingsManager sharedManager] settingForKey:key];
    return setting.title;
}
/*
- (NSArray *)tableView:(UITableView *)tableView viewsForCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger settingsSection = indexPath.section;
    if ([[KGORequestManager sharedManager] isUserLoggedIn]) {
        if (settingsSection == 0) {
            return nil;
        } else {
            settingsSection--;
        }
    }
    
    NSString *key = [_settingKeys objectAtIndex:settingsSection];
    KGOUserSetting *setting = [[KGOUserSettingsManager sharedManager] settingForKey:key];
    
    if ([key isEqualToString:@"Modules"]) {
        // special case
        NSArray *items = [setting.defaultValue objectForKey:@"items"];
        
    } else if (!setting.unrestricted) {

    }
    
    return nil;
}
*/
- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath
{
    return KGOTableCellStyleSubtitle;
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath
{
    __block NSString *cellTitle = nil;
    NSString *cellSubtitle = nil;
    NSString *accessory = nil;
    BOOL showsReorderControl = NO;
    
    NSInteger settingsSection = indexPath.section;
    if ([[KGORequestManager sharedManager] isUserLoggedIn]) {
        if (settingsSection == 0) {
            // TODO: clean up these ways of getting strings
            NSDictionary *dictionary = [[KGORequestManager sharedManager] sessionInfo];
            NSString *name = [[dictionary dictionaryForKey:@"user"] stringForKey:@"name" nilIfEmpty:YES];
            if (name) {
                cellTitle = [NSString stringWithFormat:@"%@ %@",
                             NSLocalizedString(@"You are signed in as", nil),
                             name];
            } else {
                cellTitle = NSLocalizedString(@"You are signed in anonymously", nil);
            }
            cellSubtitle = NSLocalizedString(@"Tap to sign out", nil);

        } else {
            settingsSection--;
        }
    }
    
    NSString *key = [_settingKeys objectAtIndex:settingsSection];
    KGOUserSetting *setting = [[KGOUserSettingsManager sharedManager] settingForKey:key];
    
    if ([key isEqualToString:@"Modules"]) {
        // special case
        NSDictionary *selectedDict = [[KGOUserSettingsManager sharedManager] selectedValueDictForSetting:key];
        NSArray *items = [selectedDict objectForKey:@"items"];
        NSString *moduleTag = [items objectAtIndex:indexPath.row];
        KGOModule *module = [KGO_SHARED_APP_DELEGATE() moduleForTag:moduleTag];
        cellTitle = module.longName;
        showsReorderControl = YES;
        
    } else {
        NSDictionary *currentOption = [setting.options dictionaryAtIndex:indexPath.row];
        cellTitle = [currentOption stringForKey:@"title" nilIfEmpty:NO];
        if (setting.selectedValue == currentOption) {
            accessory = KGOAccessoryTypeCheckmark;
        }
        cellSubtitle = [currentOption stringForKey:@"subtitle" nilIfEmpty:YES];
    }
        
    return [[^(UITableViewCell *cell) {
        cell.textLabel.text = cellTitle;
        cell.textLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListTitle];
        cell.textLabel.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListTitle];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.detailTextLabel.text = cellSubtitle;
        cell.detailTextLabel.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListSubtitle];
        cell.detailTextLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListSubtitle];
        if (showsReorderControl) {
            cell.showsReorderControl = showsReorderControl;
        } else {
            cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:accessory];
        }
        
    } copy] autorelease];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [super tableView:tableView viewForHeaderInSection:section];
    
    NSInteger settingsSection = section;
    if ([[KGORequestManager sharedManager] isUserLoggedIn]) {
        settingsSection--;
    }

    if (settingsSection > 0) {
        NSString *key = [_settingKeys objectAtIndex:settingsSection];
        if ([key isEqualToString:@"Modules"]) {
            if (!_editButton) {
                NSString *title = NSLocalizedString(@"Edit", @"module reordering enablement button");
                _editButton = [[UIButton genericButtonWithTitle:title] retain];
                _editButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
                CGRect frame = _editButton.frame;
                frame.origin.x = view.bounds.size.width - frame.size.width - 10;
                frame.origin.y = 5;
                _editButton.frame = frame;
                [_editButton addTarget:self action:@selector(editModuleButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            }
            if (![_editButton isDescendantOfView:view]) {
                [view addSubview:_editButton];
            }
        }
    }
    
    return view;
}

- (void)editModuleButtonPressed:(id)sender
{
    BOOL willEdit = !self.tableView.editing;
    [self.tableView setEditing:willEdit animated:YES];

    NSString *title = nil;
    if (willEdit) {
        title = NSLocalizedString(@"Done", @"module reordering enablement button");
        
    } else {
        // user clicked Done button
        NSString *moduleOrderID = [[KGOUserSettingsManager sharedManager] selectedValueForSetting:@"Modules"];
        if (![moduleOrderID isEqualToString:@"default"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:KGOUserPreferencesDidChangeNotification object:self];
        }
        title = NSLocalizedString(@"Edit", @"module reordering enablement button");
    }

    [_editButton setTitle:title forState:UIControlStateNormal];
    
    CGSize size = [title sizeWithFont:_editButton.titleLabel.font];
    CGRect frame = _editButton.frame;
    CGFloat previousWidth = frame.size.width;
    frame.size.width = size.width + 16;
    frame.origin.x -= frame.size.width - previousWidth;
    _editButton.frame = frame;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger settingsSection = indexPath.section;
    if ([[KGORequestManager sharedManager] isUserLoggedIn]) {
        if (settingsSection == 0) {
            return NO;
        }
        settingsSection--;
    }
    
    NSString *key = [_settingKeys objectAtIndex:settingsSection];
    return [key isEqualToString:@"Modules"];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSDictionary *selectedDict = [[KGOUserSettingsManager sharedManager] selectedValueDictForSetting:@"Modules"];
    NSMutableArray *items = [[[selectedDict objectForKey:@"items"] mutableCopy] autorelease];
    
    id movedObject = [items objectAtIndex:sourceIndexPath.row];
    [items removeObjectAtIndex:sourceIndexPath.row];
    [items insertObject:movedObject atIndex:destinationIndexPath.row];
    
    NSDictionary *newDict = [NSDictionary dictionaryWithObjectsAndKeys:@"id", @"selected", items, @"items", nil];
    [[KGOUserSettingsManager sharedManager] selectValue:newDict forSetting:@"Modules"];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger settingsSection = indexPath.section;
    if ([[KGORequestManager sharedManager] isUserLoggedIn]) {
        if (settingsSection == 0) {
            // currently assuming the user has to be logged in to get here
            [[KGORequestManager sharedManager] logoutKurogoServer];

        } else {
            settingsSection--;
        }
    }
    
    NSString *key = [_settingKeys objectAtIndex:settingsSection];
    KGOUserSetting *setting = [[KGOUserSettingsManager sharedManager] settingForKey:key];
    
    if (![key isEqualToString:@"Modules"]) {
        [[KGOUserSettingsManager sharedManager] selectOption:indexPath.row forSetting:setting.key];
        [[KGOUserSettingsManager sharedManager] saveSettings];
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:KGOUserPreferencesDidChangeNotification object:self];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
