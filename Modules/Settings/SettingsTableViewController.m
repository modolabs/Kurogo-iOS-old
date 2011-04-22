#import "SettingsTableViewController.h"
#import "KGOAppDelegate.h"
#import "KGOModule.h"
#import "KGOTheme.h"
#import "KGORequestManager.h"
#import "KGOSocialMediaController.h"
#import "UIKit+KGOAdditions.h"
#import "Foundation+KGOAdditions.h"

static NSString * const KGOSettingsDefaultFont = @"DefaultFont";
static NSString * const KGOSettingsDefaultFontSize = @"DefaultFontSize";
static NSString * const KGOSettingsLogin = @"Login";
static NSString * const KGOSettingsWidgets = @"Widgets";
static NSString * const KGOSettingsSocialMedia = @"SocialMedia";


@interface SettingsTableViewController (Private)

- (NSString *)readableStringForKey:(NSString *)key;

@end

@implementation SettingsTableViewController

- (NSString *)readableStringForKey:(NSString *)key
{
    if ([key isEqualToString:KGOSettingsDefaultFont]) {
        return NSLocalizedString(@"Default font", nil);
        
    } else if ([key isEqualToString:KGOSettingsDefaultFontSize]) {
        return NSLocalizedString(@"Default font size", nil);
        
    } else if ([key isEqualToString:KGOSettingsWidgets]) {
        return NSLocalizedString(@"Updates to show on home screen", nil);
        
    } else if ([key isEqualToString:KGOSettingsSocialMedia]) {
        return NSLocalizedString(@"Third party services", nil);

    } else if ([key isEqualToString:KGOSettingsLogin]) {
        return nil;
        
    }
    return key;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _availableUserSettings = [[[KGO_SHARED_APP_DELEGATE() appConfig] objectForKey:@"UserSettings"] retain];
    _setUserSettings = [[[NSUserDefaults standardUserDefaults] objectForKey:KGOUserPreferencesKey] retain];
    if (!_setUserSettings) {
        NSDictionary *defaultUserSettings = [[KGO_SHARED_APP_DELEGATE() appConfig] objectForKey:@"DefaultUserSettings"];
        if (defaultUserSettings) {
            _setUserSettings = [defaultUserSettings copy];
        }
    }

    _settingKeys = [[[_availableUserSettings allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [(NSString *)obj1 compare:(NSString *)obj2];
    }] retain];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self reloadDataForTableView:self.tableView];
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
    [_availableUserSettings release];
    [_settingKeys release];
    [_setUserSettings release];
    [super dealloc];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _availableUserSettings.count;    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *key = [_settingKeys objectAtIndex:section];
    return [[_availableUserSettings objectForKey:key] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self readableStringForKey:[_settingKeys objectAtIndex:section]];
}

- (NSArray *)tableView:(UITableView *)tableView viewsForCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [_settingKeys objectAtIndex:indexPath.section];
    if ([key isEqualToString:KGOSettingsSocialMedia]) {
        NSArray *options = [_availableUserSettings objectForKey:key];
        id optionValue = [options objectAtIndex:indexPath.row];
        if ([optionValue isKindOfClass:[NSDictionary class]]) {
            NSString *service = [optionValue stringForKey:@"service" nilIfEmpty:YES];

            NSMutableArray *views = [NSMutableArray array];
            
            CGFloat width = tableView.frame.size.width - 40; // adjust for padding and chevron
            CGFloat y = 10;
            UIFont *font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListTitle];
            UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, y, width, font.lineHeight)] autorelease];
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.font = font;
            titleLabel.text = [KGOSocialMediaController localizedNameForService:service];
            y += titleLabel.frame.size.height + 1;
            [views addObject:titleLabel];
            
            font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListSubtitle];
            NSString *string = [optionValue stringForKey:@"subtitle" nilIfEmpty:YES];
            if (string) {
                UILabel *subtitleLabel = [UILabel multilineLabelWithText:string font:font width:width];
                CGRect frame = subtitleLabel.frame;
                frame.origin.x = 10;
                frame.origin.y = y;
                subtitleLabel.frame = frame;
                y += subtitleLabel.frame.size.height + 1;
                [views addObject:subtitleLabel];
            }

            UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 45, tableView.frame.size.width - 20, font.lineHeight)] autorelease];
            label.backgroundColor = [UIColor clearColor];
            label.font = font;
            label.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListSubtitle];
            if ([[KGOSocialMediaController sharedController] isLoggedInService:service]) {
                label.text = @"Signed in - tap to sign out";
                
            } else {
                label.text = @"Not signed in - tap to sign in";
            }
            [views addObject:label];
            
            return views;
        }
    }
    
    return nil;
}

- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath
{
    return KGOTableCellStyleSubtitle;
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [_settingKeys objectAtIndex:indexPath.section];
    NSArray *options = [_availableUserSettings objectForKey:key];
    
    UIFont *cellTitleFont = nil;
    NSString *cellTitle = nil;
    NSString *cellSubtitle = nil;
    NSString *accessory = nil;
    
    id optionValue = [options objectAtIndex:indexPath.row];
    if ([key isEqualToString:KGOSettingsLogin]) {
        // TODO: clean up these ways of getting strings
        NSDictionary *dictionary = [[KGORequestManager sharedManager] sessionInfo];
        NSString *name = [[dictionary dictionaryForKey:@"user"] stringForKey:@"name" nilIfEmpty:YES];
        if (name) {
            cellTitle = [NSString stringWithFormat:@"You are signed in as %@", name];
        } else {
            cellTitle = [NSString stringWithFormat:@"You are signed in anonymously"];
        }
        cellSubtitle = @"Tap to sign out";
    
    } else if ([key isEqualToString:KGOSettingsSocialMedia]) {
        // just don't want any other branches
        
    } else if ([key isEqualToString:KGOSettingsWidgets]) {
        cellTitle = [optionValue stringForKey:@"title" nilIfEmpty:YES];
        NSString *tag = [optionValue stringForKey:@"tag" nilIfEmpty:YES];
        if ([tag isEqualToString:@"twitter"]) {
            cellSubtitle = [[NSUserDefaults standardUserDefaults] stringForKey:TwitterHashTagKey];
            
        } else if ([tag isEqualToString:@"facebook"]) {
            cellSubtitle = [[NSUserDefaults standardUserDefaults] stringForKey:FacebookGroupTitleKey];
        }
        
    } else if ([optionValue isKindOfClass:[NSString class]]) {
        cellTitle = optionValue;
        
    } else if ([optionValue isKindOfClass:[NSDictionary class]]) {
        // TODO: the current setup is not amenable to localization
        cellTitle = [optionValue stringForKey:@"title" nilIfEmpty:YES];
        cellSubtitle = [optionValue stringForKey:@"subtitle" nilIfEmpty:YES];
    }

    // special treatment for different sections
    if ([key isEqualToString:KGOSettingsDefaultFont]) {
        cellTitleFont = [[KGOTheme sharedTheme] defaultBoldFont];
        
    } else {
        cellTitleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListTitle];
    }
    
    id optionSelected = [_setUserSettings objectForKey:key];
    if ([optionSelected isKindOfClass:[NSString class]] && [optionValue isKindOfClass:[NSString class]]) {
        accessory = [optionSelected isEqualToString:optionValue] ? KGOAccessoryTypeCheckmark : KGOAccessoryTypeNone;

    } else if ([optionSelected isKindOfClass:[NSArray class]] && [optionValue isKindOfClass:[NSDictionary class]]) {
        NSString *optionTag = [optionValue stringForKey:@"tag" nilIfEmpty:YES];
        accessory = [optionSelected containsObject:optionTag] ? KGOAccessoryTypeCheckmark : KGOAccessoryTypeNone;
            
    } else {
        accessory = KGOAccessoryTypeChevron;
    }
    
    return [[^(UITableViewCell *cell) {
        cell.textLabel.text = cellTitle;
        cell.textLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListTitle];
        cell.textLabel.font = cellTitleFont;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.detailTextLabel.text = cellSubtitle;
        cell.detailTextLabel.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListSubtitle];
        cell.detailTextLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListSubtitle];
        cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:accessory];
    } copy] autorelease];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *key = [_settingKeys objectAtIndex:indexPath.section];
    NSArray *options = [_availableUserSettings objectForKey:key];
    id optionValue = [options objectAtIndex:indexPath.row];
    id optionSelected = [_setUserSettings objectForKey:key];
    id newOptionSelected = nil;
    
    if ([optionSelected isKindOfClass:[NSString class]] && [optionValue isKindOfClass:[NSString class]]) {
        if (![optionSelected isEqualToString:optionValue]) {
            newOptionSelected = optionValue;
        }
        
    } else if ([optionSelected isKindOfClass:[NSArray class]] && [optionValue isKindOfClass:[NSDictionary class]]) {
        NSString *optionTag = [optionValue stringForKey:@"tag" nilIfEmpty:YES];
        newOptionSelected = [[optionSelected mutableCopy] autorelease];
        if (!newOptionSelected) {
            newOptionSelected = [NSMutableArray array];
        }
        if ([optionSelected containsObject:optionTag]) { // remove from prefs
            [newOptionSelected removeObject:optionTag];
            
        } else { // add to prefs
            [newOptionSelected addObject:optionTag];
            
        }
        
    } else {
        if ([key isEqualToString:KGOSettingsSocialMedia] && [optionValue isKindOfClass:[NSDictionary class]]) {
            // login/logout
            NSString *service = [optionValue stringForKey:@"service" nilIfEmpty:YES];
            if (service) {
                if ([[KGOSocialMediaController sharedController] isLoggedInService:service]) {
                    [[KGOSocialMediaController sharedController] logoutService:service];
                } else {
                    [[KGOSocialMediaController sharedController] loginService:service];
                }
            }
            
        } else if ([key isEqualToString:KGOSettingsLogin]) {
            // currently assuming the user has to be logged in to get here
            [[KGORequestManager sharedManager] logoutKurogoServer];
            
        }
    }
    
    if (newOptionSelected) {
        NSMutableDictionary *dict = [[_setUserSettings mutableCopy] autorelease];
        if (!dict) {
            dict = [NSMutableDictionary dictionary];
        }
        [dict setObject:newOptionSelected forKey:key];
        [_setUserSettings release];
        _setUserSettings = [dict copy];

        [[NSUserDefaults standardUserDefaults] setObject:dict forKey:KGOUserPreferencesKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:KGOUserPreferencesDidChangeNotification object:key];
        
        [self reloadDataForTableView:tableView];
    }
}

@end
