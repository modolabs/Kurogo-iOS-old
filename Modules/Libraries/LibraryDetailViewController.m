    //
//  LibraryDetailViewController.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/19/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "LibraryDetailViewController.h"
#import "MITUIConstants.h"
#import "DiningMultiLineCell.h"
#import "MultiLineTableViewCell.h"
#import "MapBookmarkManager.h"
#import "MIT_MobileAppDelegate.h"
#import "Foundation+MITAdditions.h"


@implementation LibraryDetailViewController
@synthesize weeklySchedule;

-(void) viewDidLoad {
	
	UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:
																					[UIImage imageNamed:MITImageNameUpArrow],
																					[UIImage imageNamed:MITImageNameDownArrow], nil]];
	[segmentControl setMomentary:YES];
	[segmentControl addTarget:self action:@selector(showNextLibrary:) forControlEvents:UIControlEventValueChanged];
	segmentControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentControl.frame = CGRectMake(0, 0, 80.0, segmentControl.frame.size.height);
	UIBarButtonItem * segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView: segmentControl];
	self.navigationItem.rightBarButtonItem = segmentBarItem;
	[segmentControl release];
	[segmentBarItem release];

	
	UIView *headerView = nil; 
	NSString * libraryName = @"Cabot Science Library ";
	CGFloat height = [libraryName
					  sizeWithFont:[UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE]
					  constrainedToSize:CGSizeMake(250, 70)         
					  lineBreakMode:UILineBreakModeWordWrap].height;
	
	
	headerView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.frame.size.width, height + 15)] autorelease];
	// 
	bookmarkButton = [UIButton buttonWithType:UIButtonTypeCustom];
	bookmarkButton.frame = CGRectMake(self.tableView.frame.size.width - 60.0 , 5.0, 50.0, 50.0);
	bookmarkButton.enabled = YES;
	[bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_off.png"] forState:UIControlStateNormal];
	[bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_off_pressed.png"] forState:(UIControlStateNormal | UIControlStateHighlighted)];
	[bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on.png"] forState:UIControlStateSelected];
	[bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on_pressed.png"] forState:(UIControlStateSelected | UIControlStateHighlighted)];
	[bookmarkButton addTarget:self action:@selector(bookmarkButtonToggled:) forControlEvents:UIControlEventTouchUpInside];
	[headerView addSubview:bookmarkButton];
	//[self.tableView.tableHeaderView addSubview:myStellarButton];


	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 5.0, 250.0, height)];
	label.text = libraryName;
	label.font = [UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE];
	label.textColor = [UIColor colorWithHexString:@"#1a1611"];
	label.backgroundColor = [UIColor clearColor];	
	label.lineBreakMode = UILineBreakModeWordWrap;
	label.numberOfLines = 2;
	[headerView addSubview:label];

	
	UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, height, 250.0, 30.0)];
	label2.text = @"Affiliation: Harvard College Library";
	label2.font = [UIFont fontWithName:COURSE_NUMBER_FONT
								  size:14];
	label2.textColor = [UIColor colorWithHexString:@"#666666"];
	label2.backgroundColor = [UIColor clearColor];	
	label2.lineBreakMode = UILineBreakModeWordWrap;
	label2.numberOfLines = 2;
	[headerView addSubview:label2];

	self.tableView.tableHeaderView = [[UIView alloc]
									  initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, headerView.frame.size.height + 10)];
	[self.tableView.tableHeaderView addSubview:headerView];
	
	[self.tableView applyStandardColors];
	
	[label2 release];
	[label release];
	
	weeklySchedule = [[NSDictionary alloc] initWithObjectsAndKeys:
					  @"8.30am - 12 midnight", @"Monday",
					  @"8.30am - 12 midnight", @"Tuesday",
					  @"8.30am - 11.30pm", @"Wednesday",
					  @"8.30am - 12 midnight", @"Thursday",
					  @"8.30am - 12 midnight", @"Friday",
					  @"8.30am - 11.30pm", @"Saturday",
					  @"Closed", @"Sunday", nil];
	
	daysOfWeek = [[NSArray alloc] initWithObjects:
				  @"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday", @"Sunday", nil];
	
	
}

/*- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}*/

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


-(void) bookmarkButtonToggled: (id) sender {
}


-(void) showNextLibrary: (id) sender {
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 3;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	
	if (section == 0)
		return 4;
	
	else if (section == 2)
		return 3;
	
	else

    return 1;
}


- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

	UIView * view;
	
	return nil;
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


/*
 - (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
 {
 ShuttleStop *aStop = nil;
 if(nil != self.route && self.route.stops.count > indexPath.row) {
 aStop = [self.route.stops objectAtIndex:indexPath.row];
 }
 
 
 CGSize constraintSize = CGSizeMake(280.0f, 2009.0f);
 NSString* cellText = @"A"; // just something to guarantee one line
 UIFont* cellFont = [UIFont boldSystemFontOfSize:[UIFont buttonFontSize]];
 CGSize labelSize = [cellText sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
 
 if (aStop.upcoming)
 labelSize.height += 5.0f;
 
 return labelSize.height + 20.0f;
 }
 */


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    

	
	//if (nil != allLibraries)
		//cell.textLabel.text = @"Testing1";
	
	if (indexPath.section == 0) {
		NSString * CellTableIdentifier = @"LibDetailsHours";
		
		DiningMultiLineCell *cell = (DiningMultiLineCell *)[tableView dequeueReusableCellWithIdentifier:CellTableIdentifier];
		
		if (cell == nil)
		{
				cell = [[[DiningMultiLineCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellTableIdentifier] autorelease];
				cell.textLabelNumberOfLines = 1;
			
			cell.textLabel.textColor = [UIColor colorWithHexString:@"#554C41"];
		}
		
		if (indexPath.row <= 2) {
			
			cell.textLabel.text = [daysOfWeek objectAtIndex:indexPath.row];
			cell.detailTextLabel.text = [weeklySchedule objectForKey:[daysOfWeek objectAtIndex:indexPath.row]];
			
		}
		else if (indexPath.row == 3){
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.text = @"blank";
			cell.textLabel.textColor = [UIColor clearColor];
			
			cell.detailTextLabel.text = @"Full week's schedule";
		}
		
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
		return cell;
	}
	else if (indexPath.section == 1) {
		NSString * CellTableIdentifierLocation = @"LibLocationcell";
		DiningMultiLineCell *cellForLocation = (DiningMultiLineCell *)[tableView dequeueReusableCellWithIdentifier:CellTableIdentifierLocation];
		
		if (cellForLocation == nil)
		{
			cellForLocation = [[[DiningMultiLineCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellTableIdentifierLocation] autorelease];
			cellForLocation.textLabelNumberOfLines = 1;
			
			cellForLocation.textLabel.textColor = [UIColor colorWithHexString:@"#554C41"];
		}
			cellForLocation.textLabel.text = @"Location";
			cellForLocation.detailTextLabel.text = @"Science Center, One Oxford Street, Cambridge, MA 02140";
			cellForLocation.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
			cellForLocation.selectionStyle = UITableViewCellSelectionStyleGray;
			return cellForLocation;
		}
	
	else if (indexPath.section == 2) {
		NSString * CellTableIdentifierContact = @"LibContactcell";
		DiningMultiLineCell *cellForContact = (DiningMultiLineCell *)[tableView dequeueReusableCellWithIdentifier:CellTableIdentifierContact];
		
		if (cellForContact == nil)
		{
			cellForContact = [[[DiningMultiLineCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellTableIdentifierContact] autorelease];
			cellForContact.textLabelNumberOfLines = 1;
			
			cellForContact.textLabel.textColor = [UIColor colorWithHexString:@"#554C41"];
		}
	
		if (indexPath.row == 0) {
			cellForContact.textLabel.text = @"Website";
			cellForContact.detailTextLabel.text = @"Visit Website";
			cellForContact.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
			
		}
		else if (indexPath.row == 1) {
			cellForContact.textLabel.text = @"Email";
			cellForContact.detailTextLabel.text = @"email@harvard.edu";
			cellForContact.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
		}
		
		else if (indexPath.row == 2) {
			cellForContact.textLabel.text = @"Phone";
			cellForContact.detailTextLabel.text = @"617-617-617";
			cellForContact.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
		}
		cellForContact.selectionStyle = UITableViewCellSelectionStyleGray;
		return cellForContact;
	}
	
	else {
		static NSString *optionsForMainViewTableStringConstant = @"listViewCell";
		UITableViewCell *cell2 = nil;
		
		
		cell2 = [tableView dequeueReusableCellWithIdentifier:optionsForMainViewTableStringConstant];
		if (cell2 == nil) {
			cell2 = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:optionsForMainViewTableStringConstant] autorelease];
			//cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell2.selectionStyle = UITableViewCellSelectionStyleGray;
		}
		cell2.textLabel.text = @"Testing1";
		cell2.selectionStyle = UITableViewCellSelectionStyleGray;
		return cell2;
	}

	
	
    return nil;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if ((indexPath.section == 0) && (indexPath.row == 3)) {
		LibraryWeeklyScheduleViewController * vc = [[LibraryWeeklyScheduleViewController alloc] initWithStyle:UITableViewStyleGrouped];
		vc.title = @"Weekly Schedule";
		[vc setDaysOfWeek:daysOfWeek weeklySchedule:weeklySchedule];
		[self.navigationController pushViewController:vc animated:YES];
		[vc release];
	}
	
	else if (indexPath.section == 1) {
		[[MapBookmarkManager defaultManager] pruneNonBookmarks];

		CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(42.37640, -71.11660);
		ArcGISMapAnnotation *annotation = [[[ArcGISMapAnnotation alloc] initWithCoordinate:coord] autorelease];
		annotation.name = @"Library ABC";
		annotation.uniqueID = [NSString stringWithFormat:@"%@@%.4f,%.4f", annotation.name, coord.latitude, coord.longitude];
		[[MapBookmarkManager defaultManager] saveAnnotationWithoutBookmarking:annotation];
		
		NSURL *internalURL = [NSURL internalURLWithModuleTag:CampusMapTag
														path:LocalPathMapsSelectedAnnotation
													   query:annotation.uniqueID];
		
		[[UIApplication sharedApplication] openURL:internalURL];
	}
	
	else if (indexPath.section == 2) {

		if (indexPath.row == 0) {
			NSString *url = @"http://www.bbc.com";
			
			NSURL *eventURL = [NSURL URLWithString:url];
			if (eventURL && [[UIApplication sharedApplication] canOpenURL:eventURL]) {
				[[UIApplication sharedApplication] openURL:eventURL];
			}
			
		}
		else if (indexPath.row == 1) {
			NSString *emailAdd = @"test@test.com";
			
			NSString *subject = @"Test email about libraries";
			
			[self emailTo:subject body:@"" email:emailAdd];
		}
		
		else if (indexPath.row == 2) {
			
			NSString * phoneNum = @"617-617-617";
			NSString *phoneString = [phoneNum stringByReplacingOccurrencesOfString:@"-" withString:@""];
			NSURL *phoneURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phoneString]];
			if ([[UIApplication sharedApplication] canOpenURL:phoneURL]) {
				[[UIApplication sharedApplication] openURL:phoneURL];
			}
		}

	}
	
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{	
	NSString *cellText = nil;
	UIFont *cellFont = nil;
	NSString *detailText = nil;
    UITableViewCellAccessoryType accessoryType;
	//CGFloat constraintWidth;
	
	
	if (indexPath.section == 0) {
		cellText = [daysOfWeek objectAtIndex:indexPath.row];
		detailText = [weeklySchedule objectForKey:[daysOfWeek objectAtIndex:indexPath.row]];
		//accessoryType = nil;
	}
	else if (indexPath.section == 1) {
		cellText =  @"Location";
		detailText = @"Science Center, One Oxford Street, Cambridge, MA 02140";
		accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
	}
	else {
		cellText = @"sjdsnd";
		detailText = @"djfjdsnfdsnf";
	}
	
	CGFloat height = [detailText
					  sizeWithFont:[UIFont fontWithName:COURSE_NUMBER_FONT size:COURSE_NUMBER_FONT_SIZE]
					  constrainedToSize:CGSizeMake(self.tableView.frame.size.width*2/3, 500)         
					  lineBreakMode:UILineBreakModeWordWrap].height;

	
	if (indexPath.section == 0)	
		return [DiningMultiLineCell heightForCellWithStyle:UITableViewCellStyleValue2
                                                tableView:tableView 
                                                     text:cellText
                                             maxTextLines:1
                                               detailText:detailText
                                           maxDetailLines:4
                                                     font:cellFont 
                                               detailFont:cellFont
                                            accessoryType:accessoryType
                                                cellImage:NO];
	
	else return height + 20;
		
}


#pragma mark -
#pragma mark MFMailComposeViewController delegation

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate dismissAppModalViewControllerAnimated:YES];
}

-(void)emailTo:(NSString*)subject body:(NSString *)emailBody email:(NSString *)emailAddress {
	Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
	if ((mailClass != nil) && [mailClass canSendMail]) {
		
		MFMailComposeViewController *aController = [[MFMailComposeViewController alloc] init];
		aController.mailComposeDelegate = self;
		
		
		NSMutableArray *emailAddressArray = [NSMutableArray array];
		[emailAddressArray addObject:emailAddress];
		[aController setSubject:subject];
		[aController setToRecipients:emailAddressArray];		
		[aController setMessageBody:emailBody isHTML:NO];
		
		MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
		[appDelegate presentAppModalViewController:aController animated:YES];
		[aController release];
		
	} else {
		NSString *mailtoString = [NSString stringWithFormat:@"mailto://?subject=%@&body=%@", 
								  [subject stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
								  [emailBody stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
		
		NSURL *externURL = [NSURL URLWithString:mailtoString];
		if ([[UIApplication sharedApplication] canOpenURL:externURL])
			[[UIApplication sharedApplication] openURL:externURL];
	}
	
}

@end
