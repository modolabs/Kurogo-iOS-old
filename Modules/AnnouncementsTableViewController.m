//
//  AnnouncementsTableViewController.m
//  Harvard Mobile
//
//  Created by Muhammad Amjad on 9/22/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import "AnnouncementsTableViewController.h"
#import "MITUIConstants.h"
#import "MultiLineTableViewCell.h"
#import "AnnouncementWebViewController.h"

@implementation AnnouncementsTableViewController

@synthesize harvardAnnouncements;
@synthesize mascoAnnouncements;
@synthesize parentViewController;


#define GROUPED_VIEW_CELL_COLOR [UIColor colorWithHexString:@"#FDFAF6"] 

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



#define HEADER_FONT_COLOR [UIColor colorWithHexString:@"#808080"]
#define INSTRUCTORS_PADDING 15//was 15
#define TAS_PADDING 30
#define HEADER_HEIGHT 24//was 24




- (void)viewDidLoad {
    [super viewDidLoad];
	self.tableView.frame = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y, self.tableView.frame.size.width, 330.0);
	[self.tableView applyStandardColors];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger) numberOfSectionsInTableView: (UITableView *)tableView {
	return 2;
}

- (UIView *) sectionHeaderForTableView: (UITableView *)tableView reuseIdentifier: (NSString *)reuseIdentifier title: (NSString *)title topPadding: (CGFloat)topPadding {
	AnnouncementsTableViewHeaderCell *headerCell;
	headerCell = (AnnouncementsTableViewHeaderCell *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if(headerCell == nil) {
		headerCell = [[[AnnouncementsTableViewHeaderCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
		[headerCell applyStandardFonts];
		headerCell.selectionStyle = UITableViewCellSelectionStyleNone;
		headerCell.height = topPadding + HEADER_HEIGHT;
		
		UILabel* titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, topPadding - 10, self.view.frame.size.width - 50,35)] autorelease];
		titleLabel.text = title;
		titleLabel.backgroundColor = [UIColor clearColor];
		titleLabel.textAlignment = UITextAlignmentLeft;
		titleLabel.font = [UIFont boldSystemFontOfSize:STANDARD_CONTENT_FONT_SIZE];
		titleLabel.textColor = GROUPED_SECTION_FONT_COLOR;
		titleLabel.lineBreakMode = UILineBreakModeWordWrap;
		titleLabel.numberOfLines = 0;
		
		[headerCell addSubview:titleLabel];

	}
	return headerCell;
}

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection: (NSInteger)section {
	UIView *header = nil;
	switch (section) {
		case 0:
			header = [self sectionHeaderForTableView:tableView reuseIdentifier:@"harvardbusses" title:@"Harvard Shuttles News" topPadding:INSTRUCTORS_PADDING];
			//header =  [UITableView groupedSectionHeaderWithTitle:@"Harvard Shuttles News"];
			break;
		case 1:
			header = [self sectionHeaderForTableView:tableView reuseIdentifier:@"mascobusses" title:@"MASCO Shuttles News" topPadding:TAS_PADDING];
			//header = [UITableView groupedSectionHeaderWithTitle:@"MASCO Shuttles News"];
			break;
	}
	
	// return nil for empty sections                                                                                                                                               
	if([self tableView:tableView numberOfRowsInSection:section]) {
		header.backgroundColor = [UIColor whiteColor];
		return header;
	} else {
		return nil;
	}
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection: (NSInteger)section {
	switch (section) {
		case 0:
			return INSTRUCTORS_PADDING + HEADER_HEIGHT;
			
		case 1:
			return TAS_PADDING + HEADER_HEIGHT;
	}
	return 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	
	int rowsToReturn = 0;
	
	if (section == 0) {// harvard
		if ([self.harvardAnnouncements count] > 0)
			rowsToReturn = [self.harvardAnnouncements count];
	}
	else if (section == 1) {// MASCO
		if ([self.mascoAnnouncements count] > 0)
			rowsToReturn = [self.mascoAnnouncements count];		
	}
	
	if (rowsToReturn == 0)
		rowsToReturn = 1;
	
    return rowsToReturn;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSDictionary * announcementDetails;
	
	if (indexPath.section == 0) {// harvard
		if ([self.harvardAnnouncements count] > 0)
			announcementDetails = [self.harvardAnnouncements objectAtIndex:indexPath.row];
		else {
			announcementDetails = nil;
		}
	}
	else if (indexPath.section == 1) {// MASCO
		if ([self.mascoAnnouncements count] > 0)
			announcementDetails = [self.mascoAnnouncements objectAtIndex:indexPath.row];
		else {
			announcementDetails = nil;
		}
		
	}

	
	if (announcementDetails != nil) {
		
		static NSString *CellIdentifier = @"CellJibberish";
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		}
		
		[cell applyStandardFonts];
		makeCellWhite(cell);
		
		NSString * titleAnnouncement = [announcementDetails objectForKey:@"title"];
		NSString * dateString = [announcementDetails objectForKey:@"date"];
		BOOL * urgent = [[announcementDetails objectForKey:@"urgent"] boolValue];
		NSString * htmlString = [announcementDetails objectForKey:@"html"];
		
		cell.textLabel.text = titleAnnouncement;
		cell.detailTextLabel.text = dateString;
		cell.backgroundColor = GROUPED_VIEW_CELL_COLOR;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
		return cell;
	}
	
	else {
		static NSString *CellIdentifier = @"CellJibberish1";
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		}
		
		[cell applyStandardFonts];
		makeCellWhite(cell);
		
		cell.textLabel.text = @"No announcements at this time";
		cell.backgroundColor = GROUPED_VIEW_CELL_COLOR;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		return cell;
	}

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary * announcementDetails;
	
	if (indexPath.section == 0) {// harvard
		if ([self.harvardAnnouncements count] > 0)
			announcementDetails = [self.harvardAnnouncements objectAtIndex:indexPath.row];
		else {
			announcementDetails = nil;
		}
	}
	else if (indexPath.section == 1) {// MASCO
		if ([self.mascoAnnouncements count] > 0)
			announcementDetails = [self.mascoAnnouncements objectAtIndex:indexPath.row];
		else {
			announcementDetails = nil;
		}
		
	}
	else { //safety backup
		return 0;
	}
	
	
	UIFont *cellFont =[UIFont boldSystemFontOfSize:17];
	if (announcementDetails != nil) {
		NSString * cellText = [announcementDetails objectForKey:@"title"];
		NSString * dateString = [announcementDetails objectForKey:@"date"];
		
		
		
	    return [MultiLineTableViewCell heightForCellWithStyle:UITableViewCellStyleSubtitle
													tableView:tableView 
														 text:cellText
												 maxTextLines:0
												   detailText:dateString
											   maxDetailLines:0
														 font:cellFont 
												   detailFont:nil 
												accessoryType:UITableViewCellAccessoryDisclosureIndicator
													cellImage:NO];
	}
	
	else {
		return [MultiLineTableViewCell heightForCellWithStyle:UITableViewCellStyleSubtitle
													tableView:tableView 
														 text:@"No announcements at this time"
												 maxTextLines:0
												   detailText:nil
											   maxDetailLines:0
														 font:cellFont 
												   detailFont:nil 
												accessoryType:UITableViewCellAccessoryNone
													cellImage:NO];
	}

}


#pragma mark -
#pragma mark Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	NSDictionary * announcementDetails;
	
	if (indexPath.section == 0) {// harvard
		if ([self.harvardAnnouncements count] > 0)
			announcementDetails = [self.harvardAnnouncements objectAtIndex:indexPath.row];
		else {
			announcementDetails = nil;
		}
	}
	else if (indexPath.section == 1) {// MASCO
		if ([self.mascoAnnouncements count] > 0)
			announcementDetails = [self.mascoAnnouncements objectAtIndex:indexPath.row];
		else {
			announcementDetails = nil;
		}
	}
	
	else { //safety backup
		return;
	}
	
	if (announcementDetails != nil) {
		// Navigation logic may go here. Create and push another view controller.
		
		AnnouncementWebViewController *detailViewController = [[[AnnouncementWebViewController alloc] init] autorelease];
		//NSDictionary * announcementDetails = [self.announcements objectAtIndex:indexPath.section];
		detailViewController.titleString = [announcementDetails objectForKey:@"title"];
		detailViewController.htmlStringToDisplay = [announcementDetails objectForKey:@"html"];
		detailViewController.dateString = [announcementDetails objectForKey:@"date"];
		[self.parentViewController pushViewController:detailViewController animated:YES];
	}
	else {
		return;
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
	
	[harvardAnnouncements release];
	[mascoAnnouncements release];
	[parentViewController release];
}


- (void)dealloc {
    [super dealloc];
	[harvardAnnouncements release];
	[mascoAnnouncements release];
	[parentViewController release];
}


@end


@implementation AnnouncementsTableViewHeaderCell
@synthesize height;

- (void) drawRect: (CGRect)Rect {
	[super drawRect:Rect];
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(context, 1);
	[[UIColor grayColor] setStroke];
	
	CGPoint points[] = {CGPointMake(0, height), CGPointMake(Rect.size.width, height)};
	CGContextStrokeLineSegments(context, points, 2);
}
@end
