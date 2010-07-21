//
//  HallDetailsTableViewController.m
//  MIT Mobile
//
//  Created by Muhammad Amjad on 7/20/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import "HallDetailsTableViewController.h"



@implementation HallDetailsTableViewController

@synthesize itemDetails;

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
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
		return @"Hours";
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
	return 5;
}

-(UITableViewCell *)tableView:(UITableView *)tableView
		cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellTableIdentifier = @"HallDetailsIdentifier";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellTableIdentifier];
	
	if (cell == nil)
	{
		cell = [[[UITableViewCell alloc]
				 initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellTableIdentifier] autorelease];
	}
	
	NSInteger row = [indexPath row];
	NSInteger col = [indexPath section];
	
	if (col == 0) {
		
		NSArray *keys = [self.itemDetails allKeys];
		
		NSString *key;
		NSString *displayKey;
		
		switch (row) {
			case 0:
				key = @"breakfast_hours";
				displayKey = @"Breakfast";
				break;
			case 1:
				key = @"lunch_hours";
				displayKey = @"Lunch";
				break;
			case 2:
				key = @"dinner_hours";
				displayKey = @"Dinner";
				break;
			case 3:
				key = @"bb_hours";
				displayKey = @"Brain-Break";
				break;
			case 4:
				key = @"brunch_hours";
				displayKey = @"Brunch(Sunday)";
				break;
		}
		NSString *cellText1 = displayKey;
		cellText1 = [cellText1 stringByAppendingString:@" : "];
		NSString *cellText2 = [self.itemDetails objectForKey:key];
		cell.textLabel.text = cellText1;
		cell.detailTextLabel.text = cellText2;
		cell.selectionStyle =  UITableViewCellSelectionStyleNone;

	}
	
	if (col == 1) {
		
		cell.textLabel.text = @"Testing1";
	}

	return cell;
}

-(CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 40;
}



-(void)setDetails:(NSDictionary *)details {
	
	/*NSMutableDictionary *tempDetails = [[NSMutableDictionary alloc] init];
	
	NSArray *allKeys = [details allKeys];
	
	for (int ind=0; ind < [allKeys count]; ind++)
	{
		NSString *key = [allKeys objectAtIndex:ind];
		[tempDetails setValue:[tempDetails objectForKey:key] forKey:key];
	}
	self.itemDetails = tempDetails;*/
	
	self.itemDetails = details;

	//[tempDetails release];
}

@end
