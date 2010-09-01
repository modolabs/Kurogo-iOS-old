/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import "MenuDetailsController.h"
#import "MITUIConstants.h"


@implementation MenuDetailsController
@synthesize itemDetails;
@synthesize itemCategory;

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	//[self.tableView applyStandardColors];
}

-(void)viewDidUnload
{
	self.itemDetails = nil;
	self.itemCategory = nil;
}

- (void) dealloc
{
	[itemCategory dealloc];
	[itemDetails dealloc];
	[super dealloc];
}

#pragma mark -
#pragma mark Table Data Source Methods

-(NSInteger)tableView:(UITableView *)tableView
numberOfRowsInSection:(NSInteger)section
{
	return [self.itemDetails count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView
cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellTableIdentifier = @"CellTableIdentifier";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellTableIdentifier];
	
	if (cell == nil)
	{
		cell = [[[UITableViewCell alloc]
				 initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellTableIdentifier] autorelease];
	}

	NSInteger row = [indexPath row];

	NSString *cellText1 = (NSString *)[[self.itemCategory objectAtIndex:row] description];
	cellText1 = [cellText1 stringByAppendingString:@" : "];
	NSString *cellText2 = (NSString *)[[self.itemDetails objectAtIndex:row] description];
	cell.textLabel.text = cellText1;
	cell.detailTextLabel.text = cellText2;
	cell.selectionStyle =  UITableViewCellSelectionStyleNone;
	return cell;
}

-(CGFloat)tableView:(UITableView *)tableViewb
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 40;
}


#pragma mark -
#pragma mark Interface Method(s)

-(void)setDetails:(NSArray *)itemDet setItemCategory: (NSArray *) itemCat
{	

	NSMutableArray *tempDetails = [[NSMutableArray alloc] init];
	NSMutableArray *tempCat = [[NSMutableArray alloc] init];
	
	for (int i =0; i < [itemCat count]; i++)
	{
		NSString *tempStr = [itemCat objectAtIndex:i];
		
		if (![tempStr isEqualToString:@"item"] &&
			![tempStr isEqualToString:@"date"] &&
			![tempStr isEqualToString:@"id"] &&
			![tempStr isEqualToString:@"meal"])
			  
		{
			if (![[itemDet objectAtIndex:i] isEqualToString:@"No"]) {
			[tempDetails addObject:[itemDet objectAtIndex:i]];
			[tempCat addObject:[itemCat objectAtIndex:i]];
			}
		}
	}

	self.itemDetails = tempDetails;
	self.itemCategory = tempCat;
	
	[tempDetails release];
	[tempCat release];
}


@end
