#import "MapSettingsViewController.h"
#import "MapModule.h"

@implementation MapSettingsViewController

- (NSString *)mapTypeTitleForRow:(NSInteger)row {
    NSString *title = nil;
    switch (row) {
        case 0:
            title = NSLocalizedString(@"Standard", nil);
            break;
        case 1:
            title = NSLocalizedString(@"Satellite", nil);
            break;
        case 2:
            title = NSLocalizedString(@"Hybrid", nil);
            break;
        default:
            break;
    }
    return title;
}

- (MKMapType)mapTypeForRow:(NSInteger)row {
    switch (row) {
        case 1:
            return MKMapTypeSatellite;
        case 2:
            return MKMapTypeHybrid;
        case 0:
        default:
            return MKMapTypeStandard;
    }
}

#pragma mark -
#pragma mark Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return NSLocalizedString(@"Map Type", nil);
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 3;
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath {
    if (!_mapTypePreference) {
        _mapTypePreference = [[[NSUserDefaults standardUserDefaults] objectForKey:MapTypePreference] retain];
    }
    
    NSString *title = [self mapTypeTitleForRow:indexPath.row];
    MKMapType mapType = [self mapTypeForRow:indexPath.row];
    NSString *accessoryTag = nil;
    
    if ([_mapTypePreference integerValue] == mapType) {
        accessoryTag = KGOAccessoryTypeCheckmark;
    }
    
    return [[^(UITableViewCell *cell) {
        cell.textLabel.text = title;
        cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:accessoryTag];
    } copy] autorelease];
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MKMapType mapType = [self mapTypeForRow:indexPath.row];
    if ([_mapTypePreference integerValue] != mapType) {        
        [_mapTypePreference release];
        _mapTypePreference = [[NSNumber alloc] initWithInt:mapType];
        
        [[NSUserDefaults standardUserDefaults] setObject:_mapTypePreference forKey:MapTypePreference];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:MapTypePreferenceChanged object:_mapTypePreference];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView reloadData];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)dealloc {
    [_mapTypePreference release];
    [super dealloc];
}


@end

