    //
//  LibraryDetailViewController.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/19/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "LibraryDetailViewController.h"
#import "MITUIConstants.h"
#import "MultiLineTableViewCell.h"
#import "LibrariesMultiLineCell.h"
#import "MapBookmarkManager.h"
#import "MIT_MobileAppDelegate.h"
#import "Foundation+MITAdditions.h"
#import "LibraryPhone.h"
#import "CoreDataManager.h"
#import "Library.h"
#import "LibraryAlias.h"

@implementation LibraryDetailViewController
@synthesize weeklySchedule;
@synthesize bookmarkButtonIsOn;
@synthesize lib;
@synthesize otherLibraries;
@synthesize currentlyDisplayingLibraryAtIndex;

NSInteger phoneNumberSort(id num1, id num2, void *context);

NSInteger phoneNumberSort(id num1, id num2, void *context){
	
	LibraryPhone * phone1 = (LibraryPhone *)num1;
	LibraryPhone * phone2 = (LibraryPhone *)num2;
	
	return [phone1.descriptionText compare:phone2.descriptionText];
	
}

-(void) setupLayout {
    
    if ([self.lib.library.type isEqualToString:@"archive"])
        self.title = @"Archive Detail";
    
    else {
        self.title = @"Library Detail";
    }
	
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
	
	
	//headerView = nil; 
	NSString * libraryName;
	
	if (([lib.name isEqualToString:lib.library.primaryName]) && ([lib.library.primaryName length] > 0))
		libraryName = lib.name;
	
	else {
		libraryName = [NSString stringWithFormat:@"%@ (%@)", lib.name, lib.library.primaryName];
	}
	
	CGFloat height = [libraryName
					  sizeWithFont:[UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE]
					  constrainedToSize:CGSizeMake(250, 2000)         
					  lineBreakMode:UILineBreakModeWordWrap].height;
	
	
	UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.frame.size.width, height + 15)] autorelease];
    if (!bookmarkButton) {
        bookmarkButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        bookmarkButton.frame = CGRectMake(self.tableView.frame.size.width - 55.0 , 5.0, 50.0, 50.0);
        bookmarkButton.enabled = YES;
        [bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_off.png"] forState:UIControlStateNormal];
        [bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_off_pressed.png"] forState:(UIControlStateNormal | UIControlStateHighlighted)];
        [bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on.png"] forState:UIControlStateSelected];
        [bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on_pressed.png"] forState:(UIControlStateSelected | UIControlStateHighlighted)];
        [bookmarkButton addTarget:self action:@selector(bookmarkButtonToggled:) forControlEvents:UIControlEventTouchUpInside];
    }
	[headerView addSubview:bookmarkButton];
	
	bookmarkButtonIsOn = NO;
    
    bookmarkButton.selected = [lib.library.isBookmarked boolValue];
    bookmarkButtonIsOn = [lib.library.isBookmarked boolValue];

    UILabel *label = (UILabel *)[self.tableView.tableHeaderView viewWithTag:1234];
    if (!label) {
        label = [[[UILabel alloc] initWithFrame:CGRectMake(12.0, 9.0, 250.0, height)] autorelease];
        label.font = [UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE];
        label.textColor = [UIColor colorWithHexString:@"#1a1611"];
        label.backgroundColor = [UIColor clearColor];	
        label.lineBreakMode = UILineBreakModeWordWrap;
        label.numberOfLines = 10;
        label.tag = 1234;
    } else {
        label.frame = CGRectMake(12.0, 9.0, 250.0, height);
    }
    label.text = libraryName;
	[headerView addSubview:label];
    
    self.tableView.tableHeaderView = headerView;
	
    [self setupWeeklySchedule];
    
	if (nil == weeklySchedule) {
		weeklySchedule = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
					  @"loading...", @"Monday",
					  @"loading...", @"Tuesday",
					  @"loading...", @"Wednesday",
					  @"loading...", @"Thursday",
					  @"loading...", @"Friday",
					  @"loading...", @"Saturday",
					  @"loading...", @"Sunday", nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupLayout) name:LibraryRequestDidCompleteNotification object:LibraryDataRequestLibraryDetail];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupLayout) name:LibraryRequestDidCompleteNotification object:LibraryDataRequestArchiveDetail];

        [[LibraryDataManager sharedManager] requestDetailsForLibType:lib.library.type libID:lib.library.identityTag libName:lib.name];
    }
		
	[self setDaysOfWeekArray];
	
	websiteRow = -1;
	emailRow = -1;
	phoneRow = -1;
	
	phoneNumbersArray = [[NSArray alloc] init];
}


-(void) viewDidLoad {
	
	[self.tableView applyStandardColors];
	
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [bookmarkButton release];
	[weeklySchedule release];
    [daysOfWeek release];
    
    self.lib = nil;
    [phoneNumbersArray release];
    [footerView release];
    
    self.otherLibraries = nil;
    
    [super dealloc];
}


-(void) setDaysOfWeekArray {
	
	daysOfWeek = [[NSMutableArray alloc] initWithCapacity:7];
	
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
}


-(void) bookmarkButtonToggled: (id) sender {
	
    BOOL newBookmarkButtonStatus = !bookmarkButton.selected;
	
    //NSPredicate *pred = [NSPredicate predicateWithFormat:@"name == %@ AND type == %@", lib.name, lib.type];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"identityTag like %@", lib.library.identityTag];
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
			
			if (index == 0 && currentlyDisplayingLibraryAtIndex > 0) { // going up
				tempLibIndex = currentlyDisplayingLibraryAtIndex - 1;
			}
			else if (index == 1 && currentlyDisplayingLibraryAtIndex < [otherLibraries count]) {
				tempLibIndex = currentlyDisplayingLibraryAtIndex + 1;
            }
			
			
			if (tempLibIndex != currentlyDisplayingLibraryAtIndex){
                currentlyDisplayingLibraryAtIndex = tempLibIndex;
				
                self.lib = (LibraryAlias *)[otherLibraries objectAtIndex:tempLibIndex];
                
                [self setupLayout];
                [self.tableView reloadData];
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
		
		if ([weeklySchedule count] == 7)
			return 4;
		
		else {
			return 1;
		}

	}
	
	else if (section == 1) {
		if ([lib.library.location length] > 0)
			return 1;
	}
	
	else if (section == 2) {
		
		int count =0;
		
		if ([lib.library.websiteLib length] > 0){
			websiteRow = count;
			count++;
		}
		
		if ([lib.library.emailLib length] > 0){
			emailRow = count;
			count++;
		}
		
		if ([lib.library.phone count] > 0) {
			phoneRow = count;
			count = count + [lib.library.phone count];

            NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES];
            [phoneNumbersArray release];
			phoneNumbersArray = [[lib.library.phone sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter]] retain];
			phoneNumbersArray = [[phoneNumbersArray sortedArrayUsingFunction:phoneNumberSort context:self] retain];
		}
		return count;
	}
	

    return 0;
}


- (UIView *)tableView: (UITableView *)tableView viewForFooterInSection: (NSInteger)section{

	UIView * view = nil;
		
	if ((section == 1) && (lib.library.directions)) {
        if (!footerView) {
            NSString *text = lib.library.directions;
            UIFont *font = [UIFont fontWithName:STANDARD_FONT size:13];
            
            CGFloat width = self.view.frame.size.width - 20;
            CGFloat height = [text sizeWithFont:font
                              constrainedToSize:CGSizeMake(width, 2000)         
                                  lineBreakMode:UILineBreakModeWordWrap].height;
            
            CGRect frame = CGRectMake(12.0, 5.0, self.view.frame.size.width - 20, height);
            UILabel *footerLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
            footerLabel.text = text;
            footerLabel.font = font;
            footerLabel.textColor = [UIColor colorWithHexString:@"#554C41"];
            footerLabel.backgroundColor = [UIColor clearColor];	
            footerLabel.lineBreakMode = UILineBreakModeWordWrap;
            footerLabel.numberOfLines = 0;
            
            footerView = [[UIView alloc] initWithFrame:frame];
            [footerView addSubview:footerLabel];
        }
        view = footerView;
	}
	
	return view;
}

- (UIView *)tableView: (UITableView *)tableView viewForHeaderInSection: (NSInteger)section{
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	if (section == 1) {
		NSString * text;
		if (lib.library.directions)
			text = lib.library.directions;
		
		else {
			text =  @"Directions placeholder";
		}

		CGFloat height = [text
						  sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
						  constrainedToSize:CGSizeMake(300, 2000)         
						  lineBreakMode:UILineBreakModeWordWrap].height;
		
		return height + 10;
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
	
	if (indexPath.section == 0) {
		NSString * CellTableIdentifier = @"LibDetailsHours";
		
		LibrariesMultiLineCell *cell = (LibrariesMultiLineCell *)[tableView dequeueReusableCellWithIdentifier:CellTableIdentifier];
		
		//cell = nil;
		if (cell == nil)
		{
				cell = [[[LibrariesMultiLineCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellTableIdentifier] autorelease];
				cell.textLabelNumberOfLines = 1;
			
			cell.textLabel.textColor = [UIColor colorWithHexString:@"#554C41"];
		}
		
		if ([weeklySchedule count] == 7){
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
		else if ([weeklySchedule count] == 0){
			cell.textLabel.text = @"     ";
			cell.detailTextLabel.text = @"loading...";
		}
		else {

			NSString * hoursString = [weeklySchedule objectForKey:[[weeklySchedule allKeys] objectAtIndex:0]];
			
			NSRange range = [hoursString rangeOfString:@"http"];
			if (range.location != NSNotFound)
			{
				hoursString = [hoursString substringFromIndex:range.location];
				cell.textLabel.text = @"Hours";
				cell.detailTextLabel.text = @"See webpage";
				cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
				cell.accessoryType = UITableViewCellAccessoryNone;
			}
			else{
				cell.textLabel.text = [[weeklySchedule allKeys] objectAtIndex:0];
				cell.detailTextLabel.text = [weeklySchedule objectForKey:[[weeklySchedule allKeys] objectAtIndex:0]];
			}
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
			cellForLocation.detailTextLabel.text = lib.library.location;
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
			NSRange range = [lib.library.websiteLib rangeOfString:@"http://"];
			NSString * website = lib.library.websiteLib;
			if (range.location != NSNotFound)
				website = [lib.library.websiteLib substringFromIndex:range.location + range.length];
			
			cellForContact.detailTextLabel.text = website; //[lib.websiteLib //@"Visit Website";
			cellForContact.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
			
		}
		else if (indexPath.row == emailRow) {
			cellForContact.textLabel.text = @"Email";
			cellForContact.detailTextLabel.text = lib.library.emailLib;
			cellForContact.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
		}
		
		else if (indexPath.row >= phoneRow) {
			
			LibraryPhone * phone = nil;
			if ([phoneNumbersArray count] > 0){
				
				phone = (LibraryPhone*)[phoneNumbersArray objectAtIndex:indexPath.row - phoneRow];
			}
			
			if (nil != phone){
				cellForContact.textLabel.numberOfLines = 2;
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
	
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if ((indexPath.section == 0)) {
		if (([weeklySchedule count] == 7) && (indexPath.row == 3)){
			LibraryWeeklyScheduleViewController * vc = [[LibraryWeeklyScheduleViewController alloc] initWithStyle:UITableViewStyleGrouped];
			vc.title = @"Weekly Schedule";
            vc.daysOfTheWeek = daysOfWeek;
            vc.weeklySchedule = weeklySchedule;
			[self.navigationController pushViewController:vc animated:YES];
			[vc release];
		}
		else if ([weeklySchedule count] == 0){
			return;
		}
		else {
			// TODO: don't use -[[x allKeys] objectAtIndex:y] unless this is supposed to be random
			NSString * hoursString = [weeklySchedule objectForKey:[[weeklySchedule allKeys] objectAtIndex:0]];
			
			NSRange range = [hoursString rangeOfString:@"http"];
			if (range.location != NSNotFound)
			{
				hoursString = [hoursString substringFromIndex:range.location];
				NSURL *libURL = [NSURL URLWithString:hoursString];
				if (libURL && [[UIApplication sharedApplication] canOpenURL:libURL]) {
					[[UIApplication sharedApplication] openURL:libURL];
				}
			}
			else{
				return;
			}
		}
	}
	
	else if (indexPath.section == 1) {
		[[MapBookmarkManager defaultManager] pruneNonBookmarks];
		
		CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([lib.library.lat doubleValue], [lib.library.lon doubleValue]);
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
			NSString *url = lib.library.websiteLib;
			
			NSURL *libURL = [NSURL URLWithString:url];
			if (libURL && [[UIApplication sharedApplication] canOpenURL:libURL]) {
				[[UIApplication sharedApplication] openURL:libURL];
			}
			
		}
		else if (indexPath.row == emailRow) {
			NSString *emailAdd = lib.library.emailLib;
			
			NSString *subject = NSLocalizedString(@"Library email subject", nil);
			
			[self emailTo:subject body:NSLocalizedString(@"Library email body", nil) email:emailAdd];
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
		
		if ([weeklySchedule count] == 7){
			cellText = [daysOfWeek objectAtIndex:indexPath.row];
			detailText = [weeklySchedule objectForKey:[daysOfWeek objectAtIndex:indexPath.row]];
			//accessoryType = nil;
		}
		
		else if ([[weeklySchedule allKeys] count] == 0){
			cellText = @"     ";
			detailText = @"loading...";
		}
		else {
			cellText = [[weeklySchedule allKeys] objectAtIndex:0];
			detailText= [weeklySchedule objectForKey:[[weeklySchedule allKeys] objectAtIndex:0]];
            
            // commenting out the code below to expose data we're getting
            /*
			NSString * hoursString = [weeklySchedule objectForKey:[[weeklySchedule allKeys] objectAtIndex:0]];
			
			NSRange range = [hoursString rangeOfString:@"http"];
			if (range.location != NSNotFound)
			{
				cellText = @"Hours";
				detailText = @"See webpage";
				accessoryType = UITableViewCellAccessoryNone;
			}
			else{
                // TODO: don't use -[[x allKeys] objectAtIndex:y] unless this is supposed to be random
				cellText = [[weeklySchedule allKeys] objectAtIndex:0];
				detailText = [weeklySchedule objectForKey:[[weeklySchedule allKeys] objectAtIndex:0]];
			}
             */
		}
	}
	else if (indexPath.section == 1) {
		cellText =  @"Location";
		
		if ([lib.library.location length] > 0) {
			detailText = lib.library.location;
		} else {
			detailText = @"Location not available"; // placholder
		}

		accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
		
	}
	else {
		cellText = @"";
		detailText = @"";
		
		if (indexPath.row == websiteRow) {
			NSString *url = lib.library.websiteLib;
			detailText = url;
		}
		else if (indexPath.row == emailRow) {
			NSString *email = lib.library.emailLib;
			detailText = email;
            accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
		}
		
		else if (indexPath.row >= phoneRow) {
			
			LibraryPhone * phone = nil;
			if ([phoneNumbersArray count] > 0){
				
				phone = (LibraryPhone*)[phoneNumbersArray objectAtIndex:indexPath.row - phoneRow];
			}
			
			if (nil != phone){
				if ([phone.descriptionText length] > 0)
					cellText = phone.descriptionText;
				else
					cellText = @"Phone";
				
				if ([phone.phoneNumber length] > 0)
					detailText = phone.phoneNumber;
				
				accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
			}
			
			return [LibrariesMultiLineCell heightForCellWithStyle:UITableViewCellStyleValue2
														tableView:tableView 
															 text:cellText
													 maxTextLines:2
													   detailText:detailText
												   maxDetailLines:2
															 font:cellFont 
													   detailFont:cellFont
													accessoryType:accessoryType
														cellImage:NO];
		}
	}
	
	CGFloat height = [detailText
					  sizeWithFont:[UIFont fontWithName:BOLD_FONT size:STANDARD_CONTENT_FONT_SIZE]
					  constrainedToSize:CGSizeMake(self.tableView.frame.size.width*2/3, 500)         
					  lineBreakMode:UILineBreakModeWordWrap].height;
	
	/*if (indexPath.section == 1)
		return height;
	 */
	
	if (indexPath.section == 0)	{
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
	
    } else { 
        return height + 20;
    }
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

- (void)setupWeeklySchedule {
    
    [weeklySchedule release];
    weeklySchedule = nil;
        
    NSDictionary *libraryDictionary = [[LibraryDataManager sharedManager] scheduleForLibID:lib.library.identityTag];
    if (libraryDictionary) {
        
        [[LibraryDataManager sharedManager] unregisterDelegate:self];
        
        NSMutableDictionary *sched = [NSMutableDictionary dictionary];
        
        for (NSDictionary *wkSched in [libraryDictionary objectForKey:@"weeklyHours"]) {
            NSString *day = [wkSched objectForKey:@"day"];
            NSString *hours = [wkSched objectForKey:@"hours"];
            [sched setObject:hours forKey:day];
        }
        
        NSMutableDictionary * tempDict = [NSMutableDictionary dictionary];
        
        if ([sched count] < 7){
            [tempDict setObject:[libraryDictionary objectForKey:@"hoursOfOperationString"] forKey:@"Hours"];
            
        } else {
            for (NSString * dayOfWeek in daysOfWeek) {
                NSString *scheduleString = [sched objectForKey:dayOfWeek];
                if (!scheduleString)
                    scheduleString = @"contact library/archive";
                [tempDict setObject:scheduleString forKey:dayOfWeek];
            }
        }
        
        weeklySchedule = [tempDict retain];
        
        [self.tableView reloadData];
    }
}

- (void)requestDidFailForCommand:(NSString *)command {
    [[LibraryDataManager sharedManager] unregisterDelegate:self];
	[weeklySchedule release];
	weeklySchedule = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"unavailable", @"Hours", nil];
}

@end
