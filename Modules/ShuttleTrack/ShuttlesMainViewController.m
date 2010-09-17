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


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor clearColor];
	
	shuttleRoutesTableView = [[ShuttleRoutes alloc] initWithStyle: UITableViewStyleGrouped];
	shuttleRoutesTableView.parentViewController = self.navigationController;
	
	//tabViewContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 420.0)];
	tabViewContainer.backgroundColor = [UIColor whiteColor];
	
	
	if (_tabViewsArray == nil)
		_tabViewsArray = [[NSMutableArray alloc] initWithCapacity:3];
	
	
	[tabView addTab:@"Running"];	
	[_tabViewsArray insertObject:shuttleRoutesTableView atIndex: RunningTabIndex];
	
	[tabView addTab:@"Offline"];
	[_tabViewsArray insertObject:shuttleRoutesTableView atIndex: OfflineTabIndex];
	
	[tabView addTab:@"Contacts"];
	[_tabViewsArray insertObject:shuttleRoutesTableView atIndex: ContactsTabIndex];
	
	[tabView addTab:@"Info"];
	[_tabViewsArray insertObject:shuttleRoutesTableView atIndex: InfoTabIndex];
	
	tabView.hidden = NO;
	tabViewContainer.hidden = NO;
	
	[tabView setNeedsDisplay];
	[tabView setDelegate:self];
	
	[tabView setSelectedTab:0];
	
	[tabView setNeedsDisplay];
	
	[tabViewContainer addSubview:shuttleRoutesTableView.view];
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
	
}

@end
