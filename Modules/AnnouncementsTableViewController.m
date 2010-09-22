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

@synthesize announcements;
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


- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self.tableView applyStandardColors];
	
	
	UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(10, 0, self.view.frame.size.width - 50, 35)] autorelease];
	headerView.backgroundColor = [UIColor clearColor];
	
	UILabel* titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.view.frame.size.width - 50,35)] autorelease];
	titleLabel.text = @"Announcements:";
	titleLabel.backgroundColor = [UIColor clearColor];
	titleLabel.textAlignment = UITextAlignmentLeft;
	titleLabel.font = [UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE];
	titleLabel.lineBreakMode = UILineBreakModeWordWrap;
	titleLabel.numberOfLines = 0;
	
	[headerView addSubview:titleLabel];
	[self.tableView setTableHeaderView:headerView];
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
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [self.announcements count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"CellJibberish";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSDictionary * announcementDetails = [self.announcements objectAtIndex:indexPath.section];
	
	NSString * titleAnnouncement = [announcementDetails objectForKey:@"title"];
	NSString * dateString = [announcementDetails objectForKey:@"date"];
	BOOL * urgent = [[announcementDetails objectForKey:@"urgent"] boolValue];
	NSString * htmlString = [announcementDetails objectForKey:@"html"];

    cell.textLabel.text = titleAnnouncement;
	cell.backgroundColor = GROUPED_VIEW_CELL_COLOR;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	
    NSDictionary * announcementDetails = [self.announcements objectAtIndex:indexPath.section];
	
	NSString * cellText = [announcementDetails objectForKey:@"title"];

	UIFont *cellFont = nil;//[UIFont boldSystemFontOfSize:20];

	    return [MultiLineTableViewCell heightForCellWithStyle:UITableViewCellStyleDefault
                                                tableView:tableView 
                                                     text:cellText
                                             maxTextLines:0
                                               detailText:nil
                                           maxDetailLines:0
                                                     font:cellFont 
                                               detailFont:nil 
                                            accessoryType:UITableViewCellAccessoryDisclosureIndicator
                                                cellImage:NO];
    /*
	 
	 CGSize textSize = [cellText sizeWithFont:cellFont
	 constrainedToSize:CGSizeMake(constraintWidth, 2010.0)
	 lineBreakMode:UILineBreakModeWordWrap];
	 
	 // constant defined in MultiLineTableViewcell.h
	 return textSize.height + CELL_VERTICAL_PADDING * 2;
	 */
}


#pragma mark -
#pragma mark Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
    // Navigation logic may go here. Create and push another view controller.
	
	AnnouncementWebViewController *detailViewController = [[[AnnouncementWebViewController alloc] init] autorelease];
	NSDictionary * announcementDetails = [self.announcements objectAtIndex:indexPath.section];
	detailViewController.titleString = [announcementDetails objectForKey:@"title"];
	detailViewController.htmlStringToDisplay = [announcementDetails objectForKey:@"html"];
	[self.parentViewController pushViewController:detailViewController animated:YES];

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


@end

