#import "SettingsTableViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "MITModule.h"
#import "UITableView+MITUIAdditions.h"
#import "MITUIConstants.h"
#import "ModoThreeStateSwitchControl.h"
#import <MapKit/MapKit.h>

#define TITLE_HEIGHT 20.0
#define SUBTITLE_HEIGHT NAVIGATION_BAR_HEIGHT
#define PADDING 10.0
const CGFloat kMapTypeSwitchWidth = 180.0f;

typedef enum {
	kNotificationsSettingsSection = 0,
	kMapsSettingsSection,
	kBehaviorSettingsSection
} SettingsTableSection;

@interface SettingsTableViewController (Private)

- (UIView *)tableView:(UITableView *)tableView viewForHeaderWithTitle:(NSString *)aTitle andSubtitle:(NSString *)subtitle;
- (void)notificationSwitchDidToggle:(id)sender;
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
	titleView.textColor = GROUPED_SECTION_FONT_COLOR;
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
	[seg setFrame:CGRectMake(0, 0, kMapTypeSwitchWidth, seg.frame.size.height)];
	[seg setTintColor:[UIColor blueColor]];	
	[seg addTarget:self action:controlValueChangedHandler forControlEvents:UIControlEventValueChanged];
	[seg updateSegmentImages];

	cell.accessoryView = seg;
	[seg release];
}

#pragma mark Accessory view handlers

- (void)notificationSwitchDidToggle:(id)sender {
    UISwitch *aSwitch = sender;
    MITModule *aModule = [notifications objectAtIndex:aSwitch.tag];
    NSString *moduleTag = aModule.tag;
    
	NSMutableDictionary *parameters = [[MITDeviceRegistration identity] mutableDictionary];
	[parameters setObject:moduleTag forKey:@"module_name"];
	NSString *enabledString = aSwitch.on ? @"1" : @"0";
	[parameters setObject:enabledString forKey:@"enabled"];
	
	JSONAPIRequest *existingRequest = [apiRequests objectForKey:moduleTag];
	if (existingRequest != nil) {
		[existingRequest abortRequest];
		[apiRequests removeObjectForKey:moduleTag];
	}
	JSONAPIRequest *request = [JSONAPIRequest requestWithJSONAPIDelegate:self];
	[request requestObjectFromModule:@"push" command:@"moduleSetting" parameters:parameters];
	[apiRequests setObject:request forKey:moduleTag];
}

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

@synthesize notifications;
@synthesize apiRequests;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView applyStandardColors];
	self.apiRequests = [[NSMutableDictionary alloc] initWithCapacity:1];
	
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.notifications = [appDelegate.modules filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pushNotificationSupported == TRUE"]];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
    self.notifications = nil;
}

- (void)dealloc {
    [super dealloc];
	[self.apiRequests release];
    self.notifications = nil;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    switch (section) {
        case kNotificationsSettingsSection:
            rows = [notifications count];
            break;
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
		case kNotificationsSettingsSection:
			headerView = [self tableView:tableView viewForHeaderWithTitle:@"Notifications" 
							 andSubtitle:@"Turn off Notifications to disable alerts for that module."];
			break;
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
	
	switch (section) {
		case kNotificationsSettingsSection:
			height += SUBTITLE_HEIGHT;
			break;
		case kMapsSettingsSection:
		case kBehaviorSettingsSection:
		default:
			break;
	}
	
	return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

	NSString *label = nil;
	SEL switchToggleHandler = nil;
	BOOL switchIsOnNow = NO;
	
	switch (indexPath.section) {
        case kNotificationsSettingsSection:
		{
			MITModule *aModule = [self.notifications objectAtIndex:indexPath.row];
			label = aModule.longName;
			switchToggleHandler = @selector(notificationSwitchDidToggle:);
			switchIsOnNow = aModule.pushNotificationEnabled;
			break;
		}
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
			case kNotificationsSettingsSection:
			case kBehaviorSettingsSection:
			{
				[self addSwitchToCell:cell withToggleHandler:switchToggleHandler];
				[((UISwitch *)(cell.accessoryView)) setOn:switchIsOnNow];
				break;
			}
			case kMapsSettingsSection:
			{
				NSArray *activeSegmentImages = [NSArray arrayWithObjects:
												[UIImage imageNamed:@"map_switch_active1.png"],
												[UIImage imageNamed:@"map_switch_active2.png"],
												[UIImage imageNamed:@"map_switch_active3.png"],
												nil];
				NSArray *inactiveSegmentImages = [NSArray arrayWithObjects:
												  [UIImage imageNamed:@"map_switch_inactive1.png"],
												  [UIImage imageNamed:@"map_switch_inactive2.png"],
												  [UIImage imageNamed:@"map_switch_inactive3.png"],
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

- (void)request:(JSONAPIRequest *)request jsonLoaded: (id)object {
	if (object && [object isKindOfClass:[NSDictionary class]] && [object objectForKey:@"success"]) {
		for (id moduleTag in apiRequests) {
			JSONAPIRequest *aRequest = [apiRequests objectForKey:moduleTag];
			if (aRequest == request) {
				// this backwards finding would be a lot simpler if 
				// the backend would just return module and enabled status
				MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
				MITModule *module = [appDelegate moduleForTag:moduleTag];
				NSUInteger tag = [notifications indexOfObject:module];
				NSIndexPath *indexPath = [NSIndexPath indexPathForRow:tag inSection:0];
				[indexPath indexPathByAddingIndex:tag];
				UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
				UISwitch *aSwitch = (UISwitch *)cell.accessoryView;
				BOOL enabled = aSwitch.on;
				[module setPushNotificationEnabled:enabled];
				
				[apiRequests removeObjectForKey:moduleTag];
				break;
			}
		}
	}
}

- (void)handleConnectionFailureForRequest:(JSONAPIRequest *)request {
	for (id moduleTag in apiRequests) {
		JSONAPIRequest *aRequest = [apiRequests objectForKey:moduleTag];
		if (aRequest == request) {
			[apiRequests removeObjectForKey:moduleTag];
			break;
		}
	}
	
	//for (MITModule *aModule in notifications) {
	//	NSLog(@"%@ %@", [aModule description], aModule.pushNotificationEnabled ? @"yes" : @"no");
	//}
	
	[self reloadSettings];
	
	UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:@"Connection Failure"
                              message:@"Failed to update your settings please try again later" 
                              delegate:nil 
                              cancelButtonTitle:@"OK" 
                              otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

@end
