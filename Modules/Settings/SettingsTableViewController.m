#import "SettingsTableViewController.h"
#import "KGOAppDelegate.h"
#import "KGOModule.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"

@interface SettingsTableViewController (Private)

- (NSString *)readableStringForKey:(NSString *)key;

@end

@implementation SettingsTableViewController

- (NSString *)readableStringForKey:(NSString *)key
{
    if ([key isEqualToString:@"DefaultFont"]) {
        return NSLocalizedString(@"Default Font", nil);
        
    } else if ([key isEqualToString:@"DefaultFontSize"]) {
        return NSLocalizedString(@"Default Font Size", nil);
        
    }
    return key;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _availableUserSettings = [[[KGO_SHARED_APP_DELEGATE() appConfig] objectForKey:@"UserSettings"] retain];
    _setUserSettings = [[[NSUserDefaults standardUserDefaults] objectForKey:KGOUserPreferencesKey] retain];

    _settingKeys = [[[_availableUserSettings allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [(NSString *)obj1 compare:(NSString *)obj2];
    }] retain];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    NSString *key = [_settingKeys objectAtIndex:indexPath.section];
    NSArray *options = [_availableUserSettings objectForKey:key];
    NSString *optionValue = [options objectAtIndex:indexPath.row];
    cell.textLabel.text = optionValue;
    cell.textLabel.font = [[KGOTheme sharedTheme] defaultBoldFont]; // don't use table cell font as it may override the default
    cell.textLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListTitle];
    
    NSString *selectedOption = [_setUserSettings objectForKey:key];
    if ([selectedOption isEqualToString:optionValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [_settingKeys objectAtIndex:indexPath.section];
    NSArray *options = [_availableUserSettings objectForKey:key];
    NSString *optionValue = [options objectAtIndex:indexPath.row];

    NSString *selectedOption = [_setUserSettings objectForKey:key];
    if (![selectedOption isEqualToString:optionValue]) {
        NSMutableDictionary *dict = [[_setUserSettings mutableCopy] autorelease];
        if (!dict) {
            dict = [NSMutableDictionary dictionary];
        }
        [dict setObject:optionValue forKey:key];
        [_setUserSettings release];
        _setUserSettings = [dict copy];

        [[NSUserDefaults standardUserDefaults] setObject:dict forKey:KGOUserPreferencesKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:KGOUserPreferencesDidChangeNotification object:key];
        
        [tableView reloadData];
    }
}

@end
