//
//  HallDetailsTableViewController.m
//  MIT Mobile
//
//  Created by Muhammad Amjad on 7/20/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import "HallDetailsTableViewController.h"
#import "MITUIConstants.h"


@implementation HallDetailsTableViewController

@synthesize itemDetails;

-(void)viewWillAppear:(BOOL)animated
{	
	[super viewWillAppear:animated];
	[self.tableView applyStandardColors];
}

-(void)viewDidUnload
{
	self.itemDetails = nil;
}

- (void) dealloc
{
	[itemDetails dealloc];
	[super dealloc];
}

#pragma mark -
#pragma mark Table Data Source Methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
	if(section == 0)
		return @"";
	else
		return @"Interhouse Restrictions";
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

-(NSInteger)tableView:(UITableView *)tableView
numberOfRowsInSection:(NSInteger)section
{
	//eturn [self.itemDetails count];
	if (section == 0)
		return 5;
	
	else {
		return 3;
	}

}

-(UITableViewCell *)tableView:(UITableView *)tableView
		cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger row = [indexPath row];
	NSInteger col = [indexPath section];
	
	static NSString *CellTableIdentifier = @"HallHoursIdentifier";
	
	
	if (col == 1)
		CellTableIdentifier = @"HallRestrictionsIdentifier";
	
	//UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellTableIdentifier];
	MultiLineTableViewCell *cell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellTableIdentifier];
	
	if (cell == nil)
	{
		if (col == 0) {
		cell = [[[MultiLineTableViewCell alloc]
				 initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellTableIdentifier] autorelease];
		}
		
		if (col == 1) {
			cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellTableIdentifier] autorelease];
			cell.textLabelNumberOfLines = 2;
			//cell.textLabelLineBreakMode = UILineBreakModeTailTruncation;
		}
	}
	

	
	if (col == 0) {
		
		int status;
		int restriction;
		
		NSString *key;
		NSString *displayKey;
		
		switch (row) {
			case 0:
				key = @"breakfast_hours";
				displayKey = @"Breakfast";
				status = hallStatus.breakfast_status;
				restriction = hallStatus.breakfast_restriction;
				break;
			case 1:
				key = @"lunch_hours";
				displayKey = @"Lunch";
				status = hallStatus.lunch_status;
				restriction = hallStatus.lunch_restriction;
				break;
			case 2:
				key = @"dinner_hours";
				displayKey = @"Dinner";
				status = hallStatus.dinner_status;
				restriction = hallStatus.dinner_restriction;
				break;
			case 3:
				key = @"bb_hours";
				displayKey = @"Brain-Break(Sun-Thu)";
				status = hallStatus.bb_status;
				restriction = hallStatus.bb_restriction;
				break;
			case 4:
				key = @"brunch_hours";
				displayKey = @"Sunday Brunch";
				status = hallStatus.brunch_status;
				restriction = hallStatus.brunch_restriction;
				break;
		}
		NSString *cellText1 = displayKey;
		
		NSString *cellText2 = [self.itemDetails objectForKey:key];
		
		if ([cellText2 isEqualToString:@"NA"]) {
			cellText2 = @"";
		}
		

		cell.textLabel.text = cellText1;
		cell.detailTextLabel.text = cellText2;

		
		cell.selectionStyle =  UITableViewCellSelectionStyleNone;
		
		if ((status == OPEN) && (restriction == NO_RESTRICTION)) {
			UIImage *image = [UIImage imageNamed:@"maps/map_location.png"];
			cell.imageView.image = image;
		}
		
		else if ((status == OPEN) && (restriction = RESTRICTED)) {
			UIImage *image = [UIImage imageNamed:@"maps/map_pin.png"];
			cell.imageView.image = image;
		}
		
		else if ((status == CLOSED) && (restriction == RESTRICTED)) {
			//UIImage *image = [UIImage imageNamed:@"maps/map_pin.png"];
			//cell.imageView.image = image;
		}
		
		else {
			//UIImage *image = [UIImage imageNamed:@"global/unread-message.png"];
			//cell.imageView.image = image;
		}


	}
	
	if (col == 1) {
		
		NSString *meal;
		NSString *mealkey;
		
		switch (row) {
			case 0:
				meal = @"Lunch ";
				mealkey = @"lunch_restrictions";				
				break;
			case 1:
				meal = @"Dinner ";
				mealkey = @"dinner_restrictions";	
				break;
			case 2:
				meal = @"Sunday Brunch ";
				mealkey = @"brunch_restrictions";	
				break;
			default:
				break;
		}
		
		NSDictionary *restrictions = [self.itemDetails objectForKey:mealkey];
		NSString *message = [[restrictions valueForKey:@"message"] description];

		NSArray *messageArray = [message componentsSeparatedByString:@"\""];
		
		if ([messageArray count] == 3) {
			message = [messageArray objectAtIndex:1];
		}
		
		else {
			message = @"None";
		}

		[cell.textLabel setTextAlignment:UITextAlignmentLeft];
		cell.textLabel.text = meal;
		cell.detailTextLabel.text = message;
		cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
		cell.selectionStyle =  UITableViewCellSelectionStyleNone;		
	
	}


	return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *cellText = nil;
	UIFont *cellFont = nil;
	CGFloat constraintWidth;
	
	NSString *meal;
	NSString *mealkey;
	
	constraintWidth = tableView.frame.size.width;
	cellFont = [UIFont systemFontOfSize:15];
	
	int col = [indexPath section];
	int row = [indexPath row];
	
	if (col == 0)
		return 50;
	
	if (col == 1) {
		
		switch (row) {
			case 0:
				meal = @"Lunch ";
				mealkey = @"lunch_restrictions";				
				break;
			case 1:
				meal = @"Dinner ";
				mealkey = @"dinner_restrictions";	
				break;
			case 2:
				meal = @"Sunday Brunch ";
				mealkey = @"brunch_restrictions";	
				break;
			default:
				break;
		}
		
		NSDictionary *restrictions = [self.itemDetails objectForKey:mealkey];
		cellText = [[restrictions valueForKey:@"message"] description];
		
		NSArray *messageArray = [cellText componentsSeparatedByString:@"\""];
		
		if ([messageArray count] == 3) {
			cellText = [messageArray objectAtIndex:1];
		}
		
		else {
			cellText = @"None";
		}
		
		
	CGSize textSize = [cellText sizeWithFont:cellFont
						   constrainedToSize:CGSizeMake(constraintWidth, 5000.0)//2010.0)
							   lineBreakMode:UILineBreakModeWordWrap];
	
	// constant defined in MultiLineTableViewcell.h
		if (textSize.height < 35)
			return 40 + 20;
		
		return textSize.height + 38;
	}
	
	return 40;
}



-(void)setDetails:(NSDictionary *)details {	
	self.itemDetails = details;

}

-(void)setStatus:(DiningHallStatus *)statusDetails {
	hallStatus = statusDetails;
}

@end
