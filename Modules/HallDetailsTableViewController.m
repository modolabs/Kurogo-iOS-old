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
	//[self viewDidLoad];
	//[self.tableView applyStandardColors];
}


-(void)viewDidLoad {
	[super viewDidLoad];
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5.0, 10.0,200.0, 40.0)];
	label.text = [self.itemDetails valueForKey:@"name"];
	label.font = [UIFont boldSystemFontOfSize:25];
	label.backgroundColor = [UIColor clearColor];	
	[self.view addSubview:label];
	
	UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(250.0, 15.0, 30.0, 30.0)];
	
	switch (hallStatus.currentStat) {
		case OPEN:
			imageView.image = [UIImage imageNamed:@"dining-status-open@2x.png"];
			[self.view addSubview:imageView];
			break;
			
		case CLOSED:
			if (hallStatus.nextMealStatus == RESTRICTED) {
				imageView.image = [UIImage imageNamed:@"dining-status-closed-w-restrictions@2x.png"];
				[self.view addSubview:imageView];
			}
			else {
				imageView.image = [UIImage imageNamed:@"dining-status-closed@2x.png"];
				[self.view addSubview:imageView];
			}
			break;
			
		case NO_RESTRICTION:
			imageView.image = [UIImage imageNamed:@"dining-status-open@2x.png"];
			[self.view addSubview:imageView];
			break;
			
		case RESTRICTED:
			imageView.image = [UIImage imageNamed:@"dining-status-open-w-restrictions@2x.png"];
			[self.view addSubview:imageView];
			break;
			

	}
	
	detailsTableView = nil;
	
	detailsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 55.0, 320.0, 410.0) style: UITableViewStyleGrouped];
	[detailsTableView applyStandardColors];
	detailsTableView.delegate= self;
	detailsTableView.dataSource = self;
	detailsTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:detailsTableView];
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

	MultiLineTableViewCell *cell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellTableIdentifier];
	
	if (cell == nil)
	{
		if (col == 0) {
		cell = [[[MultiLineTableViewCell alloc]
				 initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellTableIdentifier] autorelease];
		}
		
		if (col == 1) {
			cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellTableIdentifier] autorelease];
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
				displayKey = @"breakfast";
				status = hallStatus.breakfast_status;
				restriction = hallStatus.breakfast_restriction;
				break;
			case 1:
				key = @"lunch_hours";
				displayKey = @"lunch";
				status = hallStatus.lunch_status;
				restriction = hallStatus.lunch_restriction;
				break;
			case 2:
				key = @"dinner_hours";
				displayKey = @"dinner";
				status = hallStatus.dinner_status;
				restriction = hallStatus.dinner_restriction;
				break;
			case 3:
				key = @"bb_hours";
				displayKey = @"brain break";
				status = hallStatus.bb_status;
				restriction = hallStatus.bb_restriction;
				break;
			case 4:
				key = @"brunch_hours";
				displayKey = @"brunch";
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
		
		if (row == 3) {
			cell.detailTextLabel.text = [NSString stringWithFormat:@"Sunday-Thursday %@\n",cellText2];
								
		}
			

		
		cell.selectionStyle =  UITableViewCellSelectionStyleNone;
		
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
		cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:15]; //was 15
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
	cellFont = [UIFont boldSystemFontOfSize:15]; //was 15
	
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
		
		if (textSize.height < 35)
		 return 40 + 20;
		 
		 return textSize.height + 75;
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
