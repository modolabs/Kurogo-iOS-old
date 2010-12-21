
//
//  LibraryDetailViewController.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/19/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "ItemAvailabilityLibDetailViewController.h"
#import "MITUIConstants.h"
//#import "DiningMultiLineCell.h"
#import "MultiLineTableViewCell.h"
#import "LibrariesMultiLineCell.h"
#import "MapBookmarkManager.h"
#import "MIT_MobileAppDelegate.h"
#import "Foundation+MITAdditions.h"
#import "LibraryPhone.h"
#import "CoreDataManager.h"


@implementation ItemAvailabilityLibDetailViewController
@synthesize weeklySchedule;
@synthesize bookmarkButtonIsOn;

NSInteger phoneNumberSortItemAvail(id num1, id num2, void *context);

NSInteger phoneNumberSortItemAvail(id num1, id num2, void *context){
	
	LibraryPhone * phone1 = (LibraryPhone *)num1;
	LibraryPhone * phone2 = (LibraryPhone *)num2;
	
	return [phone1.descriptionText compare:phone2.descriptionText];
	
}


-(id) initWithStyle:(UITableViewStyle)style 
		displayName: (NSString *) dispName
		 currentInd:(int) index
			library:(Library *)library
 otherLibDictionary:(NSDictionary *) otherLibDictionary
{
	
	self = [super initWithStyle:style];
	
	if (self) {
		
		displayName = dispName;
		currentlyDisplayingLibraryAtIndex = index;
		otherLibraries = [otherLibDictionary retain];
		lib = [library retain];
	}
	
	return self;
}


-(void) setupLayout {
	
	UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:
																					[UIImage imageNamed:MITImageNameUpArrow],
																					[UIImage imageNamed:MITImageNameDownArrow], nil]];
	[segmentControl setMomentary:YES];
	[segmentControl addTarget:self action:@selector(showNextLibrary:) forControlEvents:UIControlEventValueChanged];
	segmentControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentControl.frame = CGRectMake(0, 0, 80.0, segmentControl.frame.size.height);
	UIBarButtonItem * segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView: segmentControl];
	self.navigationItem.rightBarButtonItem = segmentBarItem;
	
	if (currentlyDisplayingLibraryAtIndex == 0)
		[segmentControl setEnabled:NO forSegmentAtIndex:0];
	
	if (currentlyDisplayingLibraryAtIndex == [otherLibraries count] - 1)
		[segmentControl setEnabled:NO forSegmentAtIndex:1];
	
	[segmentControl release];
	[segmentBarItem release];
	
	
	headerView = nil; 
	NSString * libraryName; //@"Cabot Science Library ";
	
	if ([displayName isEqualToString:lib.primaryName])
		libraryName = displayName;
	
	else {
		libraryName = [NSString stringWithFormat:@"%@ (%@)", displayName, lib.primaryName];
	}
	CGFloat height = [libraryName
					  sizeWithFont:[UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE]
					  constrainedToSize:CGSizeMake(250, 2000)         
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
	
	bookmarkButtonIsOn = NO;
	
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"name == %@ AND type == %@", lib.name, lib.type];
	Library *alreadyInDB = [[CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:pred] lastObject];
	
	if (nil != alreadyInDB) {
		bookmarkButton.selected = [alreadyInDB.isBookmarked boolValue];
		bookmarkButtonIsOn = [alreadyInDB.isBookmarked boolValue];
	}
	
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 5.0, 250.0, height)];
	label.text = libraryName;
	label.font = [UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE];
	label.textColor = [UIColor colorWithHexString:@"#1a1611"];
	label.backgroundColor = [UIColor clearColor];	
	label.lineBreakMode = UILineBreakModeWordWrap;
	label.numberOfLines = 10;
	[headerView addSubview:label];
	
	
	UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, height, 250.0, 30.0)];
	label2.text = @"Affiliation: Harvard College Library";
	label2.font = [UIFont fontWithName:COURSE_NUMBER_FONT
								  size:14];
	label2.textColor = [UIColor colorWithHexString:@"#666666"];
	label2.backgroundColor = [UIColor clearColor];	
	label2.lineBreakMode = UILineBreakModeWordWrap;
	label2.numberOfLines = 2;
	//[headerView addSubview:label2];
	
	self.tableView.tableHeaderView = [[UIView alloc]
									  initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, headerView.frame.size.height + 10)];
	[self.tableView.tableHeaderView addSubview:headerView];
	
	[self.tableView applyStandardColors];
	
	[label2 release];
	[label release];
	
	weeklySchedule = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
					  @"loading..", @"Monday",
					  @"loading..", @"Tuesday",
					  @"loading..", @"Wednesday",
					  @"loading..", @"Thursday",
					  @"loading..", @"Friday",
					  @"loading..", @"Saturday",
					  @"loading..", @"Sunday", nil];
	
	
	//weeklySchedule = [[NSMutableDictionary alloc] init];
	
	[self setDaysOfWeekArray];
	
	websiteRow = -1;
	emailRow = -1;
	phoneRow = -1;
	
	phoneNumbersArray = [[NSArray alloc] init];
}


-(void) viewDidLoad {
	
	[self setupLayout];
	
}

-(void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self setupLayout];
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


-(void) setDaysOfWeekArray {
	
	daysOfWeek = [[[NSMutableArray alloc] init] retain];
	
	NSDate * today = [NSDate date];
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"EEEE"];
	NSString *dayString = [dateFormat stringFromDate:today];
	
	[daysOfWeek insertObject:dayString atIndex:0];
	
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	
	NSDate *nextDate = today;
	
	for (int day=1; day < 7; day++){
		
		dayString = @"";
		
		NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
		[offsetComponents setDay:1];
		nextDate = [gregorian dateByAddingComponents:offsetComponents toDate:nextDate options:0];
		
		dayString = [dateFormat stringFromDate:nextDate];
		
		[daysOfWeek insertObject:dayString atIndex:day];
	}
	
	
	/*daysOfWeek = [[NSArray alloc] initWithObjects:
	 @"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday", @"Sunday", nil];
	 */
}


-(void) bookmarkButtonToggled: (id) sender {
	
	BOOL newBookmarkButtonStatus = !bookmarkButton.selected;
	
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"name == %@ AND type == %@", lib.name, lib.type];
	Library *alreadyInDB = [[CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:pred] lastObject];
	
	if (nil == alreadyInDB){
		return;
	}
	
	if (newBookmarkButtonStatus) {
		//[StellarModel saveClassToFavorites:stellarClass];
		
		bookmarkButton.selected = YES;
		alreadyInDB.isBookmarked = [NSNumber numberWithBool:YES];
	}
	
	else {
		//[StellarModel removeClassFromFavorites:stellarClass];
		bookmarkButton.selected = NO;
		alreadyInDB.isBookmarked = [NSNumber numberWithBool:NO];
	}
	
	[CoreDataManager saveData];
}


-(void) showNextLibrary: (id) sender {
	
	if ([sender isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl *theControl = (UISegmentedControl *)sender;
        NSInteger index = theControl.selectedSegmentIndex;
		
		if ([otherLibraries count] > 1) {
			int tempLibIndex;
			
			if (index == 0) { // going up
				
				tempLibIndex = currentlyDisplayingLibraryAtIndex - 1;
			}
			else
				tempLibIndex = currentlyDisplayingLibraryAtIndex + 1;
			
			
			if ((tempLibIndex >= 0) && (tempLibIndex < [[otherLibraries allKeys] count])){
				
				NSString * tempDispName = [[otherLibraries allKeys] objectAtIndex:tempLibIndex];
				Library * temp = (Library *)[otherLibraries objectForKey:tempDispName];
				
				NSString * libOrArchive;
				if ([temp.type isEqualToString:@"archive"])
					libOrArchive = @"archivedetail";
				
				else {
					libOrArchive = @"libdetail";
				}
				
				apiRequest = [[JSONAPIRequest alloc] initWithJSONAPIDelegate:self];
				
				if ([apiRequest requestObjectFromModule:@"libraries" 
												command:libOrArchive
											 parameters:[NSDictionary dictionaryWithObjectsAndKeys:temp.identityTag, @"id", tempDispName, @"name", nil]])
				{
					lib = [temp retain];
					currentlyDisplayingLibraryAtIndex = tempLibIndex;
					displayName = tempDispName;
					
					if (nil != headerView)
						[headerView removeFromSuperview];
					
					if (nil != footerLabel)
						[footerLabel removeFromSuperview];
					
					[self setupLayout];
					weeklySchedule = [[NSMutableDictionary alloc] init];
					
					if ([lib.type isEqualToString:@"archive"])
						self.title = @"Archive Detail";
					
					else {
						self.title = @"Library Detail";
					}
					
					
					[self.tableView reloadData];
				}
				else {
					UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
																		message:@"Could not connect to the server" 
																	   delegate:self 
															  cancelButtonTitle:@"OK" 
															  otherButtonTitles:nil];
					[alertView show];
					[alertView release];
				}
				
			}			
		}
	}	
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 3;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	
	if (section == 0){
		
		if ([[weeklySchedule allKeys] count] == 7)
			return 4;
		
		else {
			return 1;
		}
		
	}
	
	else if (section == 1) {
		if ([lib.location length] > 0)
			return 1;
	}
	
	else if (section == 2) {
		
		int count =0;
		
		if ([lib.websiteLib length] > 0){
			websiteRow = count;
			count++;
		}
		
		if ([lib.emailLib length] > 0){
			emailRow = count;
			count++;
		}
		
		if ([lib.phone count] > 0) {
			phoneRow = count;
			count = count + [lib.phone count];
			phoneNumbersArray = [lib.phone allObjects];
			phoneNumbersArray = [[phoneNumbersArray sortedArrayUsingFunction:phoneNumberSortItemAvail context:self] retain];
		}
		return count;
	}
	
	
    return 0;
}


- (UIView *)tableView: (UITableView *)tableView viewForFooterInSection: (NSInteger)section{
	
	UIView * view;
	view = nil;
	NSString * text;
	
	if ((section == 1) && (lib.directions)) {
		if (nil != footerLabel)
			[footerLabel removeFromSuperview];
		
		footerLabel = nil;
		
		text = lib.directions;
		CGFloat height = [text
						  sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
						  constrainedToSize:CGSizeMake(300, 2000)         
						  lineBreakMode:UILineBreakModeWordWrap].height;
		
		footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 0.0, 300.0, height)];
		footerLabel.text = text;
		footerLabel.font = [UIFont fontWithName:STANDARD_FONT size:13];
		footerLabel.textColor = [UIColor colorWithHexString:@"#554C41"];
		footerLabel.backgroundColor = [UIColor clearColor];	
		footerLabel.lineBreakMode = UILineBreakModeWordWrap;
		footerLabel.numberOfLines = 20;
		
		view = [[UIView alloc] initWithFrame:footerLabel.frame];
		[view addSubview:footerLabel];
	}
	
	return view;
}

- (UIView *)tableView: (UITableView *)tableView viewForHeaderInSection: (NSInteger)section{
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	if (section == 1) {
		NSString * text;
		if (lib.directions)
			text = lib.directions;
		
		else {
			text =  @"Cabot Library is located on the first floor of the Science Center"; // placeholder
		}
		
		
		//NSString * text =  @"Cabot Library is located on the first floor of the Science Center at the corner of Oxford and Kirkland Streets";
		CGFloat height = [text
						  sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
						  constrainedToSize:CGSizeMake(300, 2000)         
						  lineBreakMode:UILineBreakModeWordWrap].height;
		
		return height + 5;
	}
	
	else return 0;
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


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	
	
	//if (nil != allLibraries)
	//cell.textLabel.text = @"Testing1";
	
	if (indexPath.section == 0) {
		NSString * CellTableIdentifier = @"LibDetailsHours";
		
		LibrariesMultiLineCell *cell = (LibrariesMultiLineCell *)[tableView dequeueReusableCellWithIdentifier:CellTableIdentifier];
		
		cell = nil;
		if (cell == nil)
		{
			cell = [[[LibrariesMultiLineCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellTableIdentifier] autorelease];
			cell.textLabelNumberOfLines = 1;
			
			cell.textLabel.textColor = [UIColor colorWithHexString:@"#554C41"];
		}
		
		if ([[weeklySchedule allKeys] count] == 7){
			if (indexPath.row <= 2) {
				
				cell.textLabel.text = [daysOfWeek objectAtIndex:indexPath.row];
				
				if ([weeklySchedule count] == [daysOfWeek count])
					cell.detailTextLabel.text = [weeklySchedule objectForKey:[daysOfWeek objectAtIndex:indexPath.row]];
				
			}
			else if (indexPath.row == 3){
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.textLabel.text = @"    ";
				cell.textLabel.textColor = [UIColor clearColor];
				
				cell.detailTextLabel.text = @"Full week's schedule";
			}
		}
		else if ([[weeklySchedule allKeys] count] == 0){
			cell.textLabel.text = @"     ";
			cell.detailTextLabel.text = @"loading..";
		}
		else {
			cell.textLabel.text = [[weeklySchedule allKeys] objectAtIndex:0];
			cell.detailTextLabel.text = [weeklySchedule objectForKey:[[weeklySchedule allKeys] objectAtIndex:0]];
		}
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
		return cell;
	}
	else if (indexPath.section == 1) {
		NSString * CellTableIdentifierLocation = @"LibLocationcell";
		LibrariesMultiLineCell *cellForLocation = (LibrariesMultiLineCell *)[tableView dequeueReusableCellWithIdentifier:CellTableIdentifierLocation];
		
		cellForLocation = nil;
		if (cellForLocation == nil)
		{
			cellForLocation = [[[LibrariesMultiLineCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellTableIdentifierLocation] autorelease];
			cellForLocation.textLabelNumberOfLines = 1;
			
			cellForLocation.textLabel.textColor = [UIColor colorWithHexString:@"#554C41"];
		}
		cellForLocation.textLabel.text = @"Location";
		cellForLocation.detailTextLabel.text = lib.location;
		cellForLocation.detailTextLabel.numberOfLines = 10;
		cellForLocation.detailTextLabelNumberOfLines = 10;
		cellForLocation.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
		cellForLocation.selectionStyle = UITableViewCellSelectionStyleGray;
		return cellForLocation;
	}
	
	else if (indexPath.section == 2) {
		NSString * CellTableIdentifierContact = @"LibContactcell";
		LibrariesMultiLineCell *cellForContact = (LibrariesMultiLineCell *)[tableView dequeueReusableCellWithIdentifier:CellTableIdentifierContact];
		
		cellForContact = nil;
		if (cellForContact == nil)
		{
			cellForContact = [[[LibrariesMultiLineCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellTableIdentifierContact] autorelease];
			cellForContact.textLabelNumberOfLines = 1;
			
			cellForContact.textLabel.textColor = [UIColor colorWithHexString:@"#554C41"];
		}
		
		if (indexPath.row == websiteRow) {
			cellForContact.textLabel.text = @"Website";
			cellForContact.detailTextLabel.text = lib.websiteLib; //@"Visit Website";
			cellForContact.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
			
		}
		else if (indexPath.row == emailRow) {
			cellForContact.textLabel.text = @"Email";
			cellForContact.detailTextLabel.text = lib.emailLib;
			cellForContact.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
		}
		
		else if (indexPath.row >= phoneRow) {
			
			LibraryPhone * phone = nil;
			if ([phoneNumbersArray count] > 0){
				
				phone = (LibraryPhone*)[phoneNumbersArray objectAtIndex:indexPath.row - phoneRow];
			}
			
			if (nil != phone){
				
				if ([phone.descriptionText length] > 0)
					cellForContact.textLabel.text = phone.descriptionText;
				else
					cellForContact.textLabel.text = @"Phone";
				
				if ([phone.phoneNumber length] > 0)
					cellForContact.detailTextLabel.text = phone.phoneNumber;
				
				cellForContact.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
			}
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
		if (([[weeklySchedule allKeys] count] == 7) && (indexPath.row == 3)){
			LibraryWeeklyScheduleViewController * vc = [[LibraryWeeklyScheduleViewController alloc] initWithStyle:UITableViewStyleGrouped];
			vc.title = @"Weekly Schedule";
			[vc setDaysOfWeek:daysOfWeek weeklySchedule:weeklySchedule];
			[self.navigationController pushViewController:vc animated:YES];
			[vc release];
		}
	}
	
	else if (indexPath.section == 1) {
		[[MapBookmarkManager defaultManager] pruneNonBookmarks];
		
		CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([lib.lat doubleValue], [lib.lon doubleValue]);
		ArcGISMapAnnotation *annotation = [[[ArcGISMapAnnotation alloc] initWithCoordinate:coord] autorelease];
		annotation.name = lib.name;
		annotation.uniqueID = [NSString stringWithFormat:@"%@@%.4f,%.4f", annotation.name,coord.latitude, coord.longitude];
		[[MapBookmarkManager defaultManager] saveAnnotationWithoutBookmarking:annotation];
		
		NSURL *internalURL = [NSURL internalURLWithModuleTag:CampusMapTag
														path:LocalPathMapsSelectedAnnotation
													   query:annotation.uniqueID];
		
		[[UIApplication sharedApplication] openURL:internalURL];
	}
	
	else if (indexPath.section == 2) {
		
		if (indexPath.row == websiteRow) {
			NSString *url = lib.websiteLib;
			
			NSURL *libURL = [NSURL URLWithString:url];
			if (libURL && [[UIApplication sharedApplication] canOpenURL:libURL]) {
				[[UIApplication sharedApplication] openURL:libURL];
			}
			
		}
		else if (indexPath.row == emailRow) {
			NSString *emailAdd = lib.emailLib;
			
			NSString *subject = @"About your library";
			
			[self emailTo:subject body:@"" email:emailAdd];
		}
		
		else if (indexPath.row >= phoneRow) {
			
			LibraryPhone * phone = nil;
			if ([phoneNumbersArray count] > 0){
				
				phone = (LibraryPhone*)[phoneNumbersArray objectAtIndex:indexPath.row - phoneRow];
			}
			NSString * phoneNum = @""; 
			NSString *phoneString = [phoneNum stringByReplacingOccurrencesOfString:@"-" withString:@""];
			
			if (nil != phone){
				
				if ([phone.phoneNumber length] > 0) {
					phoneNum = phone.phoneNumber;
					phoneString = [phoneNum stringByReplacingOccurrencesOfString:@"-" withString:@""];
					phoneString = [phoneString stringByReplacingOccurrencesOfString:@"(" withString:@""];
					phoneString = [phoneString stringByReplacingOccurrencesOfString:@")" withString:@""];
					phoneString = [phoneString stringByReplacingOccurrencesOfString:@" " withString:@""];
				}
			}
			
			
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
		if ([[weeklySchedule allKeys] count] == 7){
			cellText = [daysOfWeek objectAtIndex:indexPath.row];
			detailText = [weeklySchedule objectForKey:[daysOfWeek objectAtIndex:indexPath.row]];
			//accessoryType = nil;
		}
		
		else if ([[weeklySchedule allKeys] count] == 0){
			cellText = @"     ";
			detailText = @"loading..";
		}
		else {
			cellText = [[weeklySchedule allKeys] objectAtIndex:0];
			detailText= [weeklySchedule objectForKey:[[weeklySchedule allKeys] objectAtIndex:0]];
		}
	}
	else if (indexPath.section == 1) {
		cellText =  @"Location";
		
		if ([lib.location length] > 0)
			detailText = lib.location;
		else {
			detailText = @"Cabot Scince Library is located on the second floor of blah and blah and ahfkdnfdsf"; // placholder
		}
		
		accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
	}
	else {
		cellText = @"sjdsnd";
		detailText = @"djfjdsnfdsnf";
		
		if (indexPath.row == websiteRow) {
			NSString *url = lib.websiteLib;
			detailText = url;
		}
		else if (indexPath.row == emailRow) {
			NSString *email = lib.emailLib;
			detailText = email;
		}
	}
	
	CGFloat height = [detailText
					  sizeWithFont:[UIFont fontWithName:BOLD_FONT size:STANDARD_CONTENT_FONT_SIZE]
					  constrainedToSize:CGSizeMake(self.tableView.frame.size.width*2/3, 500)         
					  lineBreakMode:UILineBreakModeWordWrap].height;
	
	/*if (indexPath.section == 1)
	 return height;
	 */
	
	if (indexPath.section == 0)	
		return [LibrariesMultiLineCell heightForCellWithStyle:UITableViewCellStyleValue2
													tableView:tableView 
														 text:cellText
												 maxTextLines:1
												   detailText:detailText
											   maxDetailLines:10
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


#pragma mark -
#pragma mark JSONAPIRequest Delegate function 

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result {
	
	NSDictionary *libraryDictionary = (NSDictionary *)result;
	
	NSString * name = [libraryDictionary objectForKey:@"name"];
	NSString * primaryName = [libraryDictionary objectForKey:@"primaryname"];
	NSString *directions = [libraryDictionary objectForKey:@"directions"];
	NSString *website = [libraryDictionary objectForKey:@"website"];
	NSString *email = [libraryDictionary objectForKey:@"email"];
	
	NSArray * phoneNumberArray = (NSArray *)[libraryDictionary objectForKey:@"phone"];
	
	NSArray * schedule = (NSArray *) [libraryDictionary objectForKey:@"weeklyHours"];
	
	directions = [directions stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	if ([lib.primaryName isEqualToString:primaryName]) {
		
		lib.primaryName = primaryName;
		lib.websiteLib = website;
		lib.emailLib = email;
		lib.directions = directions;
		
		if ([lib.phone count])
			[lib removePhone:lib.phone];
		
		
		for(NSDictionary * phNbr in phoneNumberArray) {
			
			LibraryPhone * phone = [CoreDataManager insertNewObjectForEntityForName:LibraryPhoneEntityName];
			phone.descriptionText = [phNbr objectForKey:@"description"];
			
			NSString *phNumber = [phNbr objectForKey:@"number"];
			
			if (phNumber.length == 8) {
				phNumber = [NSString stringWithFormat:@"617-%@", phNumber];
			} 
			
			phone.phoneNumber = phNumber;
			
			if (![lib.phone containsObject:phone])
				[lib addPhoneObject:phone];
			
		}
		
		NSMutableDictionary * sched = [[NSMutableDictionary alloc] init];
		
		for(NSDictionary * wkSched in schedule) {
			
			NSString * day = [wkSched objectForKey:@"day"];
			NSString *hours = [wkSched objectForKey:@"hours"];
			
			[sched setObject:hours forKey:day];
		}
		
		
		NSMutableDictionary * tempDict = [[NSMutableDictionary alloc] init];
		
		
		if ([[sched allKeys] count] < 7){
			
			[tempDict setObject:[libraryDictionary objectForKey:@"hoursOfOperationString"]forKey:@"Hours"];
		}
		else{
			for (NSString * dayOfWeek in daysOfWeek){
				
				if ([[sched allKeys] containsObject:dayOfWeek])
					[tempDict setObject:[sched objectForKey:dayOfWeek] forKey:dayOfWeek];
				
				else {
					[tempDict setObject:@"contact library/archive" forKey:dayOfWeek];
				}
				
			}
		}
		
		weeklySchedule = tempDict;
		
		[CoreDataManager saveData];
	}
	
	[self.tableView reloadData];
	//[parentViewController removeLoadingIndicator];
}

- (BOOL)request:(JSONAPIRequest *)request shouldDisplayAlertForError:(NSError *)error {
	
    return YES;
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error {
	
	weeklySchedule = nil;
	weeklySchedule = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
					  @"unavailable", @"Hours", nil];
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
														message:@"Could not retrieve Libraries/Archives" 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}


@end

