//
//  HallDetailsTableViewController.m
//  MIT Mobile
//
//  Created by Muhammad Amjad on 7/20/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import "HallDetailsTableViewController.h"
#import "MITUIConstants.h"
#import "DiningMultiLineCell.h"


@implementation HallDetailsTableViewController

@synthesize itemDetails;

-(void)viewWillAppear:(BOOL)animated
{	
	[super viewWillAppear:animated];
}


-(void)viewDidLoad {
	[super viewDidLoad];
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 4.0,200.0, 40.0)];
	label.text = [self.itemDetails valueForKey:@"name"];
	label.font = [UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE];
	label.textColor = [UIColor colorWithHexString:@"#1a1611"];
	label.backgroundColor = [UIColor clearColor];	
	[self.view addSubview:label];
    [label release];
	
	UIImageView *imageView = [[[UIImageView alloc] initWithFrame:CGRectMake(282.0, 9.0, 30.0, 30.0)] autorelease];
	
	switch (hallStatus.currentStat) {
		case OPEN:
			imageView.image = [UIImage imageNamed:@"dining/dining-status-open@2x.png"];
			[self.view addSubview:imageView];
			break;
			
		case CLOSED:
			if (hallStatus.nextMealRestriction == RESTRICTED) {
				imageView.image = [UIImage imageNamed:@"dining/dining-status-closed-w-restrictions@2x.png"];
				[self.view addSubview:imageView];
			}
			else {
				imageView.image = [UIImage imageNamed:@"dining/dining-status-closed@2x.png"];
				[self.view addSubview:imageView];
			}
			break;
			
		case NO_RESTRICTION:
			imageView.image = [UIImage imageNamed:@"dining/dining-status-open@2x.png"];
			[self.view addSubview:imageView];
			break;
			
		case RESTRICTED:
			imageView.image = [UIImage imageNamed:@"dining/dining-status-open-w-restrictions@2x.png"];
			[self.view addSubview:imageView];
			break;
	}
	
	detailsTableView = nil;
	
	detailsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 36.0, 320.0, 410.0) style: UITableViewStyleGrouped];
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


- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = nil; 
	
	if (section == 0) {
		view = [[[UIView alloc] initWithFrame:CGRectMake(12.0, 0.0, 300.0, 40.0)] autorelease];
		UILabel *text = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 0.0, 300.0, 40.0)];
		text.text = @"Harvard student ID required. Schedule shown does not account for holidays and other closures.";
		text.font = [UIFont fontWithName:STANDARD_FONT size:12.0];
		text.textColor = [UIColor colorWithHexString:@"#666666"];
		text.lineBreakMode = UILineBreakModeWordWrap;
		text.numberOfLines = 2;
		text.backgroundColor = [UIColor clearColor];
		[view addSubview:text];
		[text release];
	}
    
    if(section != 0)
        view = [UITableView groupedSectionHeaderWithTitle:@"Interhouse Restrictions"];

    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 45.0;
    }
    else
    {
		return GROUPED_SECTION_HEADER_HEIGHT;
    }
    
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
	
	NSString *CellTableIdentifier = @"HallHoursIdentifier";
	
	
	if (col == 1)
		CellTableIdentifier = @"HallRestrictionsIdentifier";

	DiningMultiLineCell *cell = (DiningMultiLineCell *)[tableView dequeueReusableCellWithIdentifier:CellTableIdentifier];
	
	if (cell == nil)
	{
		if (col == 0) {
		cell = [[[DiningMultiLineCell alloc]
				 initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellTableIdentifier] autorelease];
			cell.textLabelNumberOfLines = 1;
		}
		
		if (col == 1) {
			cell = [[[DiningMultiLineCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellTableIdentifier] autorelease];
			cell.textLabelNumberOfLines = 1;
			//cell.textLabelLineBreakMode = UILineBreakModeTailTruncation;
		}
        
        cell.textLabel.textColor = [UIColor colorWithHexString:@"#554C41"];
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
		
		if ([cellText1 isEqualToString:@"brunch"]) {
			cellText2 = [[NSString alloc] initWithFormat:@"Sunday %@", cellText2];
		}
		
		if ([cellText2 isEqualToString:@"NA"]) {
			cellText2 = @"Closed";
		}

		cell.textLabel.text = cellText1;
		cell.detailTextLabel.text = cellText2;
		
		
		if ([hallStatus.hallName isEqualToString:@"Hillel"]) {
			
			if (row == 1) {
				cell.detailTextLabel.text = @"Saturday only";
			}
			
			else if (row == 2) {
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (Sunday-Thursday)", cellText2];
			}
		}
		
		else if ([hallStatus.hallName isEqualToString:@"Fly-By"]) {
			
			if (row == 1) {
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (Monday-Friday)", cellText2];
			}
		}
		
		if ((row == 3) && ![cellText2 isEqualToString:@"Closed"]) {
			cell.detailTextLabel.text = [NSString stringWithFormat:@"Sunday-Thursday %@\n",cellText2];
								
		}
			
		
		cell.selectionStyle =  UITableViewCellSelectionStyleNone;
		
	}
	
	if (col == 1) {
		
		NSString *meal;
		NSString *mealkey;
		
		switch (row) {
			case 0:
				meal = @"lunch";
				mealkey = @"lunch_restrictions";				
				break;
			case 1:
				meal = @"dinner";
				mealkey = @"dinner_restrictions";	
				break;
			case 2:
				meal = @"brunch";
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

		//[cell.textLabel setTextAlignment:UITextAlignmentLeft];
		cell.textLabel.text = meal;
		cell.detailTextLabel.text = message;
		cell.detailTextLabel.font = [UIFont systemFontOfSize:CELL_STANDARD_FONT_SIZE];
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
	cellFont = [UIFont systemFontOfSize:CELL_STANDARD_FONT_SIZE]; //was 15
	
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
		
		if ([cellText length] > 25) {
			
	CGSize textSize = [cellText sizeWithFont:cellFont
						   constrainedToSize:CGSizeMake(constraintWidth, 5000.0)//5000.0)//2010.0)
							   lineBreakMode:UILineBreakModeWordWrap];
		
		if (textSize.height < 40)
		 return 60;

		else if (textSize.height < 65)
			return textSize.height + 45;
			
		else if (textSize.height < 100)
			return textSize.height + 75;
		
		else if (textSize.height > 100)
			return textSize.height + 75;
			
		 return textSize.height + 55;
		
		//return textSize.height + 20;
		}
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
