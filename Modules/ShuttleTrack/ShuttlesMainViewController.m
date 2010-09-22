//
//  ShuttlesMainViewController.m
//  Harvard Mobile
//
//  Created by Muhammad Amjad on 9/17/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import "ShuttlesMainViewController.h"

#define RunningTabIndex 0
#define OfflineTabIndex 1
#define ContactsTabIndex 2
#define InfoTabIndex 3

@implementation ShuttlesMainViewController

NSString * const shuttleExtension = @"shuttles/";


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	newAnnouncement.hidden = YES;
	
	self.view.backgroundColor = [UIColor clearColor];
	
	shuttleRoutesTableView = [[ShuttleRoutes alloc] initWithStyle: UITableViewStyleGrouped];
	shuttleRoutesTableView.parentViewController = self.navigationController;
	
	//tabViewContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 420.0)];
	tabViewContainer.backgroundColor = [UIColor whiteColor];
	
	announcementsTab  = [[AnnouncementsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
	announcementsTab.parentViewController = self.navigationController;
	
	JSONAPIRequest *api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
	BOOL dispatched = [api requestObject:[NSDictionary dictionaryWithObjectsAndKeys:@"announcements", @"command", nil]
						   pathExtension:shuttleExtension];
	
	if (dispatched == NO)
		[self couldNotConnectToServer];
	
	if (_tabViewsArray == nil)
		_tabViewsArray = [[NSMutableArray alloc] initWithCapacity:3];
	
	
	[tabView addTab:@"Running"];	
	[_tabViewsArray insertObject:shuttleRoutesTableView.view atIndex: RunningTabIndex];
	
	[tabView addTab:@"Offline"];
	[_tabViewsArray insertObject:shuttleRoutesTableView.view atIndex: OfflineTabIndex];
	
	[tabView addTab:@"Contacts"];
	[_tabViewsArray insertObject:shuttleRoutesTableView.view atIndex: ContactsTabIndex];
	
	[tabView addTab:@"Info"];
	[_tabViewsArray insertObject:announcementsTab.view atIndex: InfoTabIndex];

	[tabView setDelegate:self];
	tabView.hidden = NO;
	tabViewContainer.hidden = NO;
	
	[tabView setNeedsDisplay];
	[tabView setDelegate:self];
	
	[tabView setSelectedTab:0];
	shuttleRoutesTableView.currentTabMainView = RunningTabIndex;
	
	[tabView setNeedsDisplay];
	
	[tabViewContainer addSubview:shuttleRoutesTableView.view];
	//[tabViewContainer addSubview:webView];
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    
	[tabView release];
	[tabViewContainer release];
	[shuttleRoutesTableView release];
	[super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
	[tabView release];
	[tabViewContainer release];
	[shuttleRoutesTableView release];
}


#pragma mark - TabViewControlDelegate methods
-(void) tabControl:(ShuttlesTabViewControl*)control changedToIndex:(int)tabIndex tabText:(NSString*)tabText{
	
	// change the content based on the tab that was selected
	for(UIView* subview in [tabView subviews])
	{
		[subview removeFromSuperview];
	}
	
	if (tabIndex == RunningTabIndex) {
		announcementsTab.view.hidden = YES;
		shuttleRoutesTableView.currentTabMainView = RunningTabIndex;
		[shuttleRoutesTableView setShuttleRoutes:shuttleRoutesTableView.shuttleRoutes];
		[shuttleRoutesTableView.tableView reloadData];
		[tabViewContainer addSubview:[_tabViewsArray objectAtIndex:tabIndex]];
		shuttleRoutesTableView.view.hidden = NO;
	}
	
	else if (tabIndex == OfflineTabIndex) {
		announcementsTab.view.hidden = YES;
		shuttleRoutesTableView.currentTabMainView = OfflineTabIndex;
		[shuttleRoutesTableView setShuttleRoutes:shuttleRoutesTableView.shuttleRoutes];
		[shuttleRoutesTableView.tableView reloadData];
		[tabViewContainer addSubview:[_tabViewsArray objectAtIndex:tabIndex]];
		shuttleRoutesTableView.view.hidden = NO;
	}
	
	else if (tabIndex == ContactsTabIndex) {
		announcementsTab.view.hidden = YES;
		shuttleRoutesTableView.currentTabMainView = ContactsTabIndex;
		[shuttleRoutesTableView setShuttleRoutes:shuttleRoutesTableView.shuttleRoutes];
		[shuttleRoutesTableView.tableView reloadData];
		[tabViewContainer addSubview:[_tabViewsArray objectAtIndex:tabIndex]];
		shuttleRoutesTableView.view.hidden = NO;
	}
	
	else {
		shuttleRoutesTableView.view.hidden = YES;
		[tabViewContainer addSubview:[_tabViewsArray objectAtIndex:tabIndex]];
		[announcementsTab.tableView reloadData];
		announcementsTab.view.hidden = NO;
	}
	
	

}


- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result {
	
	NSArray * agencies =(NSArray *)[result objectForKey:@"agencies"];	
	NSMutableArray * announcementsTemp = [[NSMutableArray alloc] init];
	
	int new = 0;
	
	for (int i =0; i < [agencies count]; i++) {
		
		NSDictionary * agency = (NSDictionary *)[agencies objectAtIndex:i];
		
		NSArray * announcements = [agency objectForKey:@"announcements"];
		
		for (int j =0; j < [announcements count]; j ++) {
			[announcementsTemp addObject:[announcements objectAtIndex:j]];
			NSDictionary * announcementDetails = [announcements objectAtIndex:j];
			BOOL urgent = [[announcementDetails objectForKey:@"urgent"] boolValue];
			NSString * dateString = [announcementDetails objectForKey:@"date"];
			
			NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"YYYY/MM/dd"];
			NSDate* dateAnnouncement = [dateFormatter dateFromString:dateString];
			
			NSDate *today = [NSDate date];
			
			if (([today timeIntervalSinceDate:dateAnnouncement] <= (48*60*60)) || (urgent == YES)) {
				new++;
			}
		}
	}
	
	announcementsTab.announcements = announcementsTemp;
	[announcementsTab.tableView reloadData];
	
	if (new > 0)
		newAnnouncement.hidden = NO;
	
	else
		newAnnouncement.hidden = YES;
}

-(void)couldNotConnectToServer {
}

@end
