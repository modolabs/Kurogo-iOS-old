//
//  HoursTableViewController.m
//  MIT Mobile
//
//  Created by Muhammad Amjad on 7/19/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import "HoursTableViewController.h"
#import "MITUIConstants.h"

@implementation HoursTableViewController

@synthesize hallProperties;
@synthesize parentViewController;

#pragma mark -
#pragma mark Initialization

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
    }
    return self;
}
*/

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
	[self.tableView applyStandardColors];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/


#pragma mark -
#pragma mark Table view data source
/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}*/


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	
	if (self.hallProperties != nil)
		return [self.hallProperties count];
	
	else return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"HallHours";
    
    MultiLineTableViewCell *cell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
	
	
	cell.detailTextLabelNumberOfLines = 2;
	cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
	
	int row = [indexPath row];
    
    // Configure the cell...
    cell.textLabel.text = [[self.hallProperties objectAtIndex:row] objectForKey:@"name"];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	
	DiningHallStatus *status = [[DiningHallStatus alloc] init];
	int stat = [status getStatusOfMeal:@"" usingDetails:[self.hallProperties objectAtIndex:row]];
	
	NSString *statString;
	if (stat == 1)
		statString = @"Open";
	if (stat == 2)
		statString = @"Closed";
	if (stat == 3)
		statString = @"No Interhosue Restriction";
	if (stat == 4)
		statString = @"Open";
	
	//cell.textLabel.text = [[[self.hallProperties objectAtIndex:row] objectForKey:@"name"] stringByAppendingString:statString];
	cell.textLabel.text = [[self.hallProperties objectAtIndex:row] objectForKey:@"name"];
	
	if ((stat == 1) || (stat == 3)) {
		statString = [statString stringByAppendingString:@" for "];
		statString = [statString stringByAppendingString:status.currentMeal];
		statString = [statString stringByAppendingString:status.currentMealTime];
		cell.detailTextLabel.text = statString;

		UIImage *image = [UIImage imageNamed:@"maps/map_location.png"];
		cell.imageView.image = image;
		
	}
	
	else if (stat == 4) {
		statString = [statString stringByAppendingString:@" for "];
		statString = [statString stringByAppendingString:status.currentMeal];
		statString = [statString stringByAppendingString:status.currentMealTime];
		//cell.detailTextLabel.text = statString;
		
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\n,No Interhouse"];
		UIImage *image = [UIImage imageNamed:@"maps/map_pin.png"];
		cell.imageView.image = image;
	}
	

	else {
		if (status.nextMeal != nil) {
			NSString *nextMeal = status.nextMeal;
			
			//if (status.nextMealRestriction == RESTRICTED)
			//	nextMeal = [NSString stringWithFormat:@"%@. No Interhouse", nextMeal]; //[nextMeal stringByAppendingString:@", No Interhouse"];
			
			cell.detailTextLabel.text = [NSString stringWithFormat:@"Closed.\nNext Meal: %@ %@", nextMeal, status.nextMealTime];
		}
		
		else {
			cell.detailTextLabel.text = @"Closed";
		}

		
		UIImage *image = [UIImage imageNamed:@"global/unread-message.png"];
		cell.imageView.image = image;
	}
	
	[status release];
    return cell;
}



#pragma mark -
#pragma mark Table view delegate


-(void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	//re-initialize the childController each time to get the correct Display
	childHallViewController = nil;
	
	if (childHallViewController == nil)
	{
		childHallViewController = [[HallDetailsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
	}

	
	NSUInteger row = [indexPath row];
	
	DiningHallStatus *status = [[DiningHallStatus alloc] init];
	[status getStatusOfMeal:@"" usingDetails:[self.hallProperties objectAtIndex:row]];
	
	NSDictionary *test = [self.hallProperties objectAtIndex:row];
	[childHallViewController setDetails:test];
	[childHallViewController setStatus:status];
	childHallViewController.title = [[self.hallProperties objectAtIndex:row] objectForKey:@"name"];

	[self.parentViewController.navigationController pushViewController:childHallViewController animated:YES];
	// deselect the Row
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	int row = [indexPath row];
    
	DiningHallStatus *status = [[DiningHallStatus alloc] init];
	int stat = [status getStatusOfMeal:@"" usingDetails:[self.hallProperties objectAtIndex:row]];

	if (stat == 1)
		return 40.0;
	
	else {
		return 60.0;
	}

	
	
	
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


#pragma mark -
#pragma mark JSONAPIRequest Delegate function 

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result {
	
	NSMutableArray *properties = [[NSMutableArray alloc] init];
	
	for (int index=0; index < [result count]; index++) {
		NSDictionary *dict = [result objectAtIndex:index];
		[properties addObject:dict];	
	}
	
	self.hallProperties = properties;
	[self.tableView reloadData];
	[parentViewController removeLoadingIndicator];
}


- (void)handleConnectionFailureForRequest:(JSONAPIRequest *)request
{
	
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Failed"
                                                    message:@"Could not retrieve The Dining Halls Infomation"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
	
    [alert show];
    [alert release];
}
@end

