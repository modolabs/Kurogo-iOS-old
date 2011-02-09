#import "SettingsTableViewController.h"
#import "KGOAppDelegate.h"
#import "KGOModule.h"
#import "MITUIConstants.h"
#import "ModoThreeStateSwitchControl.h"
#import <MapKit/MapKit.h>
#import "KGOTheme.h"

#define TITLE_HEIGHT 20.0
#define SUBTITLE_HEIGHT NAVIGATION_BAR_HEIGHT
#define PADDING 10.0
const CGFloat kMapTypeSwitchWidth = 180.0f;
const CGFloat kMapTypeSwitchHeight = 29.0f;

typedef enum {
	kMapsSettingsSection = 0,
	kBehaviorSettingsSection
} SettingsTableSection;

@interface SettingsTableViewController (Private)

- (UIView *)tableView:(UITableView *)tableView viewForHeaderWithTitle:(NSString *)aTitle andSubtitle:(NSString *)subtitle;
- (void)behaviorSwitchDidToggle:(id)sender;
- (void)addSwitchToCell:(UITableViewCell *)cell withToggleHandler:(SEL)switchToggleHandler;
- (void)addSegmentedControlToCell:(UITableViewCell *)cell 
				withToggleHandler:(SEL)controlValueChangedHandler 
			  activeSegmentImages:(NSArray *)activeImages 
			inactiveSegmentImages:(NSArray *)activeImages
			   activeSegmentIndex:(NSInteger)index;

@end

@implementation SettingsTableViewController (Private)

- (UIView *)tableView:(UITableView *)tableView viewForHeaderWithTitle:(NSString *)aTitle andSubtitle:(NSString *)subtitle {
	UIView *result = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, SUBTITLE_HEIGHT + TITLE_HEIGHT)] autorelease];
	
	UILabel *titleView = [[UILabel alloc] initWithFrame:CGRectMake(PADDING, PADDING, 200, TITLE_HEIGHT)];
	titleView.font = [UIFont boldSystemFontOfSize:STANDARD_CONTENT_FONT_SIZE];
	titleView.textColor = [[KGOTheme sharedTheme] textColorForGroupedSectionHeader];
	titleView.backgroundColor = [UIColor clearColor];
	titleView.text = aTitle;
	
	[result addSubview:titleView];
	[titleView release];
	
	if ([subtitle length] > 0) {
		UILabel *subtitleView = [[UILabel alloc] initWithFrame:CGRectMake(PADDING, round(TITLE_HEIGHT + 1.5 * PADDING), round(tableView.frame.size.width-2 * PADDING), SUBTITLE_HEIGHT)];
		subtitleView.numberOfLines = 0;
		subtitleView.backgroundColor = [UIColor clearColor];
		subtitleView.lineBreakMode = UILineBreakModeWordWrap;
		subtitleView.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
		subtitleView.text = subtitle;	
		[result addSubview:subtitleView];
		[subtitleView release];
	}
	
	return result;
}

- (void)addSwitchToCell:(UITableViewCell *)cell withToggleHandler:(SEL)switchToggleHandler {
	
	UISwitch *aSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
	cell.accessoryView = aSwitch;
	if (switchToggleHandler) {
		[aSwitch addTarget:self action:switchToggleHandler forControlEvents:UIControlEventValueChanged];
	}
	[aSwitch release];	
}

- (void)addSegmentedControlToCell:(UITableViewCell *)cell 
				withToggleHandler:(SEL)controlValueChangedHandler 
			  activeSegmentImages:(NSArray *)activeImages 
			inactiveSegmentImages:(NSArray *)inactiveImages
			   activeSegmentIndex:(NSInteger)index {
	
	ModoThreeStateSwitchControl* seg = [[ModoThreeStateSwitchControl alloc] initWithActiveSegmentImages:activeImages 
																			   andInactiveSegmentImages:inactiveImages];
	[seg setSelectedSegmentIndex:index];
	[seg setSegmentedControlStyle:UISegmentedControlStyleBar];
	[seg setFrame:CGRectMake(0, 0, kMapTypeSwitchWidth, kMapTypeSwitchHeight)];
	[seg addTarget:self action:controlValueChangedHandler forControlEvents:UIControlEventValueChanged];
	[seg updateSegmentImages];

	cell.accessoryView = seg;
	[seg release];
}

#pragma mark Accessory view handlers

- (void)behaviorSwitchDidToggle:(id)sender {
	// If there are ever other behavior switches, check the sender's tag before doing anything.
	BOOL currentShakePref = [[NSUserDefaults standardUserDefaults] boolForKey:ShakeToReturnPrefKey];
	[[NSUserDefaults standardUserDefaults] setBool:!currentShakePref forKey:ShakeToReturnPrefKey];
}

- (void)mapControlDidChangeValue:(id)sender {
	if ([sender isKindOfClass:[ModoThreeStateSwitchControl class]])
	{
		ModoThreeStateSwitchControl *threeSwitch = (ModoThreeStateSwitchControl *)sender;
		[threeSwitch updateSegmentImages];
		// Save preference.
		MKMapType mapType = MKMapTypeStandard;
		// Map types and segmented indexes might coincide, but just to be safe let's check the index, then assign a map type.
		switch ([threeSwitch selectedSegmentIndex]) {
			case 0:
				break;
			case 1:
				mapType = MKMapTypeSatellite;
				break;
			case 2:
				mapType = MKMapTypeHybrid;
				break;
			default:
				break;
		}
		[[NSUserDefaults standardUserDefaults] setInteger:mapType forKey:MapTypePrefKey];
	}
}

- (NSInteger)segmentIndexForMapType:(MKMapType)mapType {
	switch (mapType) {
		case MKMapTypeStandard:
			return 0;
		case MKMapTypeSatellite:
			return 1;
		case MKMapTypeHybrid:
			return 2;
		default:
			return 0;
	}	
}
	
@end

@implementation SettingsTableViewController
/*
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/
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
    [super dealloc];
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    switch (section) {
		case kMapsSettingsSection:
			rows = 1;
			break;
		case kBehaviorSettingsSection:
			rows = 1;
			break;			
        default:
            rows = 0;
            break;
    }
    return rows;
}

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	
	UIView *headerView = nil;
	
	switch (section) {
		case kMapsSettingsSection:
			headerView = [self tableView:tableView viewForHeaderWithTitle:@"Maps" andSubtitle:nil];
			break;
		case kBehaviorSettingsSection:
			headerView = [self tableView:tableView viewForHeaderWithTitle:@"Behavior" andSubtitle:nil];
		default:
			break;
	}
	
	return headerView;
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	CGFloat height = TITLE_HEIGHT + 2.5 * PADDING;
		
	return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

	NSString *label = nil;
	SEL switchToggleHandler = nil;
	BOOL switchIsOnNow = NO;
	
	switch (indexPath.section) {
		case kMapsSettingsSection:
		{
			label = @"Map Type";
			switchToggleHandler = @selector(mapControlDidChangeValue:);
			break;
		}
		case kBehaviorSettingsSection:
		{
			label = @"Shake To Go Home";
			switchToggleHandler = @selector(behaviorSwitchDidToggle:);
			switchIsOnNow = [[NSUserDefaults standardUserDefaults] boolForKey:ShakeToReturnPrefKey];
			break;
		}
        default:
            break;
    }
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];
		
		switch (indexPath.section) {
			case kBehaviorSettingsSection:
			{
				[self addSwitchToCell:cell withToggleHandler:switchToggleHandler];
				[((UISwitch *)(cell.accessoryView)) setOn:switchIsOnNow];
				break;
			}
			case kMapsSettingsSection:
			{
				NSArray *activeSegmentImages = [NSArray arrayWithObjects:
												[UIImage imageNamed:@"settings/map_switch_active1.png"],
												[UIImage imageNamed:@"settings/map_switch_active2.png"],
												[UIImage imageNamed:@"settings/map_switch_active3.png"],
												nil];
				NSArray *inactiveSegmentImages = [NSArray arrayWithObjects:
												  [UIImage imageNamed:@"settings/map_switch_inactive1.png"],
												  [UIImage imageNamed:@"settings/map_switch_inactive2.png"],
												  [UIImage imageNamed:@"settings/map_switch_inactive3.png"],
												  nil];
				[self addSegmentedControlToCell:cell 
							  withToggleHandler:switchToggleHandler 
							activeSegmentImages:activeSegmentImages
						  inactiveSegmentImages:inactiveSegmentImages
							 activeSegmentIndex:[self segmentIndexForMapType:
												 [[NSUserDefaults standardUserDefaults] integerForKey:MapTypePrefKey]]];
				break;
			}	
			default:
				break;
		}
    }            
    
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.text = label;
    cell.detailTextLabel.text = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView.tag = indexPath.row;
    
    return cell;    
}

- (void) reloadSettings {
	[self.tableView reloadData];
}

@end
