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

@synthesize settingKeys = _settingKeys;

- (void)loadSettings
{
    _headerViews = [[NSMutableDictionary alloc] init];
    
    NSMutableArray *settingKeys = [NSMutableArray array];

    if ([[KGORequestManager sharedManager] isUserLoggedIn]) {
        [settingKeys addObject:KGOUserSettingKeyLogin];
    }

    NSArray *settingsOrder = [NSArray arrayWithObjects:
                              KGOUserSettingKeyServer,
                              KGOUserSettingKeyPrimaryModules,
                              KGOUserSettingKeySecondaryModules,
                              KGOUserSettingKeyFont,
                              KGOUserSettingKeyFontSize, nil];
    
    for (NSString *aKey in settingsOrder) {
        if ([[KGOUserSettingsManager sharedManager] settingForKey:aKey]) {
            [settingKeys addObject:aKey];
        }
    }

    self.settingKeys = settingKeys;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadSettings];
}

- (void)viewWillAppear:(BOOL)animated
{
    // will need to refresh data if some state was changed via a modal view
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
    self.settingKeys = nil;
    [_headerViews release];
    [super dealloc];
}

- (void)settingDidChange:(NSNotification *)aNotification
{
    [self reloadDataForTableView:self.tableView];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.settingKeys.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *key = [self.settingKeys objectAtIndex:section];
    if ([key isEqualToString:KGOUserSettingKeyLogin]) {
        return 1;
    }
    
    KGOUserSetting *setting = [[KGOUserSettingsManager sharedManager] settingForKey:key];
    return setting.options.count;
}

- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath
{
    return KGOTableCellStyleSubtitle;
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath
{
    __block NSString *cellTitle = nil;
    NSString *cellSubtitle = nil;
    BOOL showsReorderControl = NO;
    NSString *accessory = nil;
    NSString *key = [self.settingKeys objectAtIndex:indexPath.section];
    UIButton *button = nil; // this is a checkbox

    if ([key isEqualToString:KGOUserSettingKeyLogin]) {
        NSDictionary *dictionary = [[KGORequestManager sharedManager] sessionInfo];
        NSString *name = [[dictionary dictionaryForKey:@"user"] nonemptyStringForKey:@"name"];
        if (name) {
            cellTitle = [NSString stringWithFormat:NSLocalizedString(@"You are signed in as %@", nil), name];
        } else {
            cellTitle = NSLocalizedString(@"You are signed in anonymously", nil);
        }
        cellSubtitle = NSLocalizedString(@"Tap to sign out", nil);

    } else {
        
        KGOUserSetting *setting = [[KGOUserSettingsManager sharedManager] settingForKey:key];
        
        NSDictionary *currentOption = [setting.options dictionaryAtIndex:indexPath.row];
        cellTitle = [currentOption stringForKey:@"title"];
        if (setting.selectedValue == currentOption) {
            accessory = KGOAccessoryTypeCheckmark;
        }
        cellSubtitle = [currentOption nonemptyStringForKey:@"subtitle"];
        
        if (([key isEqualToString:KGOUserSettingKeyPrimaryModules] && _isEditingPrimary)
            || ([key isEqualToString:KGOUserSettingKeySecondaryModules] && _isEditingSecondary)) 
        {
            showsReorderControl = YES;
            
            ModuleTag *moduleTag = [currentOption stringForKey:@"tag"];
            BOOL isHidden = [[KGOUserSettingsManager sharedManager] isModuleHidden:moduleTag primary:_isEditingPrimary];
            UIImage *image = nil;
            if (isHidden) {
                image = [UIImage imageWithPathName:@"common/checkbox-unchecked"];
            } else {
                image = [UIImage imageWithPathName:@"common/checkbox-checked"];
            }
            
            button = [UIButton buttonWithType:UIButtonTypeCustom];
            [button setImage:image forState:UIControlStateNormal];
            button.frame = CGRectMake(8, 8, image.size.width, image.size.height);
            button.tag = indexPath.row;
            
            if (_isEditingPrimary) {
                [button addTarget:self action:@selector(primaryModuleToggled:) forControlEvents:UIControlEventTouchUpInside];
            } else {
                [button addTarget:self action:@selector(secondaryModuleToggled:) forControlEvents:UIControlEventTouchUpInside];
            }
        }
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
        
        if (button) {
            cell.imageView.image = [UIImage blankImageOfSize:button.frame.size];
            [cell.contentView addSubview:button];
        } else {
            for (UIView *aView in cell.contentView.subviews) {
                if ([aView isKindOfClass:[UIButton class]]) {
                    [aView removeFromSuperview];
                }
            }
            cell.imageView.image = nil;
        }
        
    } copy] autorelease];
}

- (void)moduleToggledBySender:(id)sender isPrimary:(BOOL)primary
{
    NSString *settingKey = primary ? KGOUserSettingKeyPrimaryModules : KGOUserSettingKeySecondaryModules;
    if ([sender isKindOfClass:[UIView class]]) {
        UIView *view = (UIView *)sender;
        KGOUserSetting *setting = [[KGOUserSettingsManager sharedManager] settingForKey:settingKey];
        NSDictionary *currentDict = [setting.options dictionaryAtIndex:view.tag];
        ModuleTag *tag = [currentDict stringForKey:@"tag"];
        [[KGOUserSettingsManager sharedManager] toggleModuleHidden:tag primary:primary];
        NSInteger section = [self.settingKeys indexOfObject:settingKey];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:view.tag inSection:section];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                              withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)primaryModuleToggled:(id)sender
{
    [self moduleToggledBySender:sender isPrimary:YES];
}

- (void)secondaryModuleToggled:(id)sender
{
    [self moduleToggledBySender:sender isPrimary:NO];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *key = [self.settingKeys objectAtIndex:section];
    KGOUserSetting *setting = [[KGOUserSettingsManager sharedManager] settingForKey:key];
    return setting.title;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];
    UIView *view = [_headerViews objectForKey:title];
    if (!view) {
        // this will exists as long as the title is there
        view = [super tableView:tableView viewForHeaderInSection:section];
    }
    if (view) {
        NSString *key = [self.settingKeys objectAtIndex:section];
        
        UIButton *editButton = nil;
        BOOL isPrimaryModuleSection = [key isEqualToString:KGOUserSettingKeyPrimaryModules];
        BOOL isSecondaryModuleSection = [key isEqualToString:KGOUserSettingKeySecondaryModules];
        
        if (isPrimaryModuleSection) {
            editButton = _primaryEditButton;
            
        } else if (isSecondaryModuleSection) {
            editButton = _secondaryEditButton;
        }
        
        if ((isPrimaryModuleSection || isSecondaryModuleSection) && !editButton) {
            NSString *title = NSLocalizedString(@"Edit", @"module reordering enablement button");
            editButton = [UIButton genericButtonWithTitle:title];
            editButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            CGRect frame = editButton.frame;
            frame.origin.x = view.bounds.size.width - frame.size.width - 10;
            frame.origin.y = 5;
            editButton.frame = frame;
            [editButton addTarget:self action:@selector(editModuleButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            if (isSecondaryModuleSection) {
                _secondaryEditButton = editButton;
            } else {
                _primaryEditButton = editButton;
            }
        }
        
        [view addSubview:editButton];

        [_headerViews setObject:view forKey:title];
    }
    
    return view;
}

- (void)editModuleButtonPressed:(id)sender
{
    NSString *editTitle = NSLocalizedString(@"Edit", @"module reordering button");
    NSString *doneTitle = NSLocalizedString(@"Done", @"module reordering button");
    
    // only allow one section to be edited at a time
    if ((sender == _primaryEditButton && _isEditingPrimary)
        || (sender == _secondaryEditButton && _isEditingSecondary))
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:ModuleListDidChangeNotification
                                                            object:self];
        _isEditingPrimary = NO;
        _isEditingSecondary = NO;
    } else if (sender == _primaryEditButton && !_isEditingPrimary) {
        _isEditingPrimary = YES;
        _isEditingSecondary = NO;
    } else if (sender == _secondaryEditButton && !_isEditingSecondary) {
        _isEditingPrimary = NO;
        _isEditingSecondary = YES;
    } else {
        _isEditingPrimary = NO;
        _isEditingSecondary = NO;
    }

    BOOL tableShouldBeEditing = _isEditingPrimary || _isEditingSecondary;
    
    if (tableShouldBeEditing && !self.tableView.editing) {
        [self.tableView setEditing:YES animated:YES];
    } else if (!tableShouldBeEditing && self.tableView.editing) {
        [self.tableView setEditing:NO animated:YES];
    }

    void (^setButtonTitle)(UIButton *, NSString *) = ^(UIButton *button, NSString *title) {
        [button setTitle:title forState:UIControlStateNormal];
        CGSize size = [title sizeWithFont:button.titleLabel.font];
        CGRect frame = button.frame;
        CGFloat previousWidth = frame.size.width;
        frame.size.width = size.width + 16;
        frame.origin.x -= frame.size.width - previousWidth;
        button.frame = frame;
    };

    if (_primaryEditButton) {
        NSString *title = _isEditingPrimary ? doneTitle : editTitle;
        setButtonTitle(_primaryEditButton, title);
    }
    if (_secondaryEditButton) {
        NSString *title = _isEditingSecondary ? doneTitle : editTitle;
        setButtonTitle(_secondaryEditButton, title);
    }
    
    NSMutableIndexSet *indexSetToReload = [NSMutableIndexSet indexSet];
    NSInteger index = [self.settingKeys indexOfObject:KGOUserSettingKeyPrimaryModules];
    if (index != NSNotFound) {
        [indexSetToReload addIndex:index];
    }
    index = [self.settingKeys indexOfObject:KGOUserSettingKeySecondaryModules];
    if (index != NSNotFound) {
        [indexSetToReload addIndex:index];
    }
    [self.tableView reloadSections:indexSetToReload withRowAnimation:UITableViewRowAnimationNone];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [self.settingKeys objectAtIndex:indexPath.section];
    // one section at a time
    if ([key isEqualToString:KGOUserSettingKeyPrimaryModules] && _isEditingPrimary) {
        return YES;
    }
    if ([key isEqualToString:KGOUserSettingKeySecondaryModules] && _isEditingSecondary) {
        return YES;
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSAssert(sourceIndexPath.section == destinationIndexPath.section, @"source index path must match dest index path");
    
    NSString *key = [self.settingKeys objectAtIndex:sourceIndexPath.section];
    KGOUserSetting *setting = [[KGOUserSettingsManager sharedManager] settingForKey:key];
    NSMutableArray *modules = [[setting.options mutableCopy] autorelease];

    id movedObject = [modules objectAtIndex:sourceIndexPath.row];
    [modules removeObjectAtIndex:sourceIndexPath.row];
    [modules insertObject:movedObject atIndex:destinationIndexPath.row];
    
    [[KGOUserSettingsManager sharedManager] setModuleOrder:modules primary:_isEditingPrimary];
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
    NSString *key = [self.settingKeys objectAtIndex:indexPath.section];
    
    if ([key isEqualToString:KGOUserSettingKeyLogin]) {
        [[KGORequestManager sharedManager] logoutKurogoServer];
        
    } else if (![key isEqualToString:KGOUserSettingKeyPrimaryModules] && ![key isEqualToString:KGOUserSettingKeySecondaryModules]) {
        KGOUserSetting *setting = [[KGOUserSettingsManager sharedManager] settingForKey:key];
        [[KGOUserSettingsManager sharedManager] selectOption:indexPath.row forSetting:setting.key];
        [[KGOUserSettingsManager sharedManager] saveSettings];
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
        [[NSNotificationCenter defaultCenter] postNotificationName:KGOUserPreferencesDidChangeNotification object:self];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
