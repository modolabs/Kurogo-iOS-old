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


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	
	if (self.hallProperties != nil)
		return [self.hallProperties count];
	
	else return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"HallHours";
    
    DiningMultiLineCell *cell = (DiningMultiLineCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[DiningMultiLineCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
	
	
	cell.detailTextLabelNumberOfLines = 2;
	cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
	cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
	
	int row = [indexPath row];
    
    // Configure the cell...
    cell.textLabel.text = [[self.hallProperties objectAtIndex:row] objectForKey:@"name"];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	
	DiningHallStatus *status = [[DiningHallStatus alloc] init];
	status.hallName = cell.textLabel.text;
	int stat = [status getStatusOfMeal:@"" usingDetails:[self.hallProperties objectAtIndex:row]];
	
	NSString *statString;
	if (stat == OPEN)
		statString = @"Open";
	if (stat == CLOSED)
		statString = @"Closed";
	if (stat == NO_RESTRICTION)
		statString = @"No Interhouse Restriction";
	if (stat == RESTRICTED)
		statString = @"Open";
	
	//cell.textLabel.text = [[[self.hallProperties objectAtIndex:row] objectForKey:@"name"] stringByAppendingString:statString];
	cell.textLabel.text = [[self.hallProperties objectAtIndex:row] objectForKey:@"name"];
	
	if ((stat == OPEN) || (stat == NO_RESTRICTION)) {
		statString = [statString stringByAppendingString:@" for "];
		statString = [statString stringByAppendingString:status.currentMeal];
		statString = [statString stringByAppendingString:@" "];
		statString = [statString stringByAppendingString:status.currentMealTime];
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\n", statString];

		UIImage *image = [UIImage imageNamed:@"dining/dining-status-open.png"];
		cell.imageView.image = image;
		
	}
	
	else if (stat == RESTRICTED) {
		statString = [statString stringByAppendingString:@" for "];
		statString = [statString stringByAppendingString:status.currentMeal];
		statString = [statString stringByAppendingString:@" "];
		statString = [statString stringByAppendingString:status.currentMealTime];
		//cell.detailTextLabel.text = statString;
		
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\nNo Interhouse", statString];
		UIImage *image = [UIImage imageNamed:@"dining/dining-status-open-w-restrictions.png"];
		cell.imageView.image = image;
	}
	

	else {
		if (status.nextMeal != nil) {
			NSString *nextMeal = status.nextMeal;
			
			nextMeal = [nextMeal stringByAppendingString:status.nextMealTime];
			cell.detailTextLabel.text = [NSString stringWithFormat:@"Closed.\nNext Meal: %@", nextMeal];
			
			UIImage *image = [UIImage imageNamed:@"dining/dining-status-closed.png"];
			cell.imageView.image = image;
			
			if (status.nextMealRestriction == RESTRICTED) {
				//nextMeal = [NSString stringWithFormat:@"%@. No Interhouse", nextMeal]; 
				
				cell.detailTextLabel.text = [NSString stringWithFormat:@"Closed. Upcoming Restriction\nNext Meal: %@", nextMeal];
				
				UIImage *image = [UIImage imageNamed:@"dining/dining-status-closed-w-restrictions.png"];
				cell.imageView.image = image;
			}
			
		}
		
		else {
			cell.detailTextLabel.text = @"Closed";
			
			
			UIImage *image = [UIImage imageNamed:@"dining/dining-status-closed.png"];
			cell.imageView.image = image;
		}

	}
	
	[status release];
	
	cell.backgroundColor = GROUPED_VIEW_CELL_COLOR;
	
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
		//childHallViewController = [[HallDetailsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
		childHallViewController = [[HallDetailsTableViewController alloc] init];
	}

	
	NSUInteger row = [indexPath row];
	
	DiningHallStatus *status = [[DiningHallStatus alloc] init];
	status.hallName = [[self.hallProperties objectAtIndex:row] objectForKey:@"name"];
	int stat = [status getStatusOfMeal:@"" usingDetails:[self.hallProperties objectAtIndex:row]];
	
	[status setStat:stat];
	
	NSDictionary *test = [self.hallProperties objectAtIndex:row];
	[childHallViewController setDetails:test];
	[childHallViewController setStatus:status];
	childHallViewController.title =  @"Dining Hall Details"; //[[self.hallProperties objectAtIndex:row] objectForKey:@"name"];

	[self.parentViewController.navigationController pushViewController:childHallViewController animated:YES];
	// deselect the Row
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	int row = [indexPath row];
    
	DiningHallStatus *status = [[DiningHallStatus alloc] init];
	int stat = [status getStatusOfMeal:@"" usingDetails:[self.hallProperties objectAtIndex:row]];
    [status release];

	if (stat == 1)
		return 50.0;
	
	else {
		return 65.0;
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
	
	self.hallProperties = nil;
	childHallViewController = nil;
}


- (void)dealloc {
	[hallProperties release];
	[childHallViewController release];
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

- (BOOL)request:(JSONAPIRequest *)request shouldDisplayAlertForError:(NSError *)error {
    return YES;
}

@end

