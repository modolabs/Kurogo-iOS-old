//
//  LibItemDetailViewController.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/24/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "LibItemDetailViewController.h"
#import "MITUIConstants.h"
#import "LibItemDetailCell.h"
#import "CoreDataManager.h"
#import "ItemAvailabilityDetailViewController.h"
#import "LibraryLocationsMapViewController.h"
#import "LibrariesSearchViewController.h"

@class LibItemDetailCell;

@implementation LibItemDetailViewController
@synthesize bookmarkButtonIsOn;


#pragma mark -
#pragma mark Initialization

-(id) initWithStyle:(UITableViewStyle)style 
		libraryItem:(LibraryItem *) libraryItem
		  itemArray: (NSDictionary *) results
	currentItemIdex: (int) itemIndex	{
	
	self = [super initWithStyle:style];
	
	if (self) {

		libItem = [libraryItem retain];
		libItemDictionary = [results retain];
		currentIndex = itemIndex;
		
		[self setUpdetails:libItem];
		
		self.tableView.delegate = self;
		self.tableView.dataSource = self;
		
		locationsWithItem = [[NSArray alloc] init];
	}
	
	return self;
}


-(void)setUpdetails: (LibraryItem *) libraryItem {
	
	
	NSString * title = libraryItem.title;
	NSString * authorName =  libraryItem.author;
	NSString * otherDetail1 = @"";
	if([libraryItem.edition length] > 0)
		otherDetail1 = libraryItem.edition;
	
	NSString * otherDetail2 = @"";
	
	if (nil != libraryItem.publisher) {
		otherDetail2 = [NSString stringWithFormat:@"%@, %@" ,libraryItem.publisher, libraryItem.year];
	}
	else {
		otherDetail2 = [NSString stringWithFormat:@"%@", libraryItem.year];
	}
	
	
	NSString * otherDetail3 = @"";
	
	if (([libraryItem.formatDetail length] > 0) && ([libraryItem.typeDetail length] > 0))
		otherDetail3 = [NSString stringWithFormat:@"%@: %@", libraryItem.formatDetail, libraryItem.typeDetail];
	
	else if (([libraryItem.formatDetail length] == 0) && ([libraryItem.typeDetail length] > 0))
		otherDetail3 = [NSString stringWithFormat:@"%@", libraryItem.typeDetail];
	
	else if (([libraryItem.formatDetail length] > 0) && ([libraryItem.typeDetail length] == 0))
		otherDetail3 = [NSString stringWithFormat:@"%@", libraryItem.formatDetail];
	
	itemTitle = [title retain];
	author = [authorName retain];
	otherDetailLine1 = [otherDetail1 retain];
	otherDetailLine2 = [otherDetail2 retain];
	otherDetailLine3 = [otherDetail3 retain];
	
	currentLocation = nil;
}


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
	[self setupLayout];
	
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self setupLayout];
}


- (void) setupLayout{
	UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:
																					[UIImage imageNamed:MITImageNameUpArrow],
																					[UIImage imageNamed:MITImageNameDownArrow], nil]];
	[segmentControl setMomentary:YES];
	[segmentControl addTarget:self action:@selector(showNextLibItem:) forControlEvents:UIControlEventValueChanged];
	segmentControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentControl.frame = CGRectMake(0, 0, 80.0, segmentControl.frame.size.height);
	UIBarButtonItem * segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView: segmentControl];
	self.navigationItem.rightBarButtonItem = segmentBarItem;
	
	if (currentIndex == 0)
		[segmentControl setEnabled:NO forSegmentAtIndex:0];
	
	if (currentIndex == [libItemDictionary count] - 1)
		[segmentControl setEnabled:NO forSegmentAtIndex:1];
	
	[segmentControl release];
	[segmentBarItem release];
	
	CGFloat runningYDispacement = 0.0;
	CGFloat titleHeight = [itemTitle
						   sizeWithFont:[UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE]
						   constrainedToSize:CGSizeMake(300, 2000)         
						   lineBreakMode:UILineBreakModeWordWrap].height;
	
	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 10.0, 300.0, titleHeight)];
	
	runningYDispacement += titleHeight;
	
	titleLabel.text = itemTitle;
	titleLabel.font = [UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE];
	titleLabel.textColor = [UIColor colorWithHexString:@"#1a1611"];
	titleLabel.backgroundColor = [UIColor clearColor];	
	titleLabel.lineBreakMode = UILineBreakModeWordWrap;
	titleLabel.numberOfLines = 10;
	
	
	CGFloat authorHeight = [author
							sizeWithFont:[UIFont fontWithName:COURSE_NUMBER_FONT size:15]
							constrainedToSize:CGSizeMake(190, 20)         
							lineBreakMode:UILineBreakModeWordWrap].height;
	
	UnderlinedUILabel *authorLabel = [[UnderlinedUILabel alloc] initWithFrame:CGRectMake(12.0, 20 + runningYDispacement, 190.0, authorHeight)];
	
	UIButton * authorButton = [UIButton buttonWithType:UIButtonTypeCustom];
	authorButton.frame = CGRectMake(12.0, 20 + runningYDispacement, 190.0, authorHeight);
	[authorButton addTarget:self action:@selector(authorLinkTapped:) forControlEvents:UIControlEventTouchUpInside];
	authorButton.enabled = YES;
	
	if (authorHeight >= 20)
		runningYDispacement += authorHeight;
	
	else {
		runningYDispacement += 20;
	}

	authorLabel.text = author;
	authorLabel.font = [UIFont fontWithName:COURSE_NUMBER_FONT size:14];
	authorLabel.textColor = [UIColor colorWithHexString:@"#8C000B"]; 
	authorLabel.backgroundColor = [UIColor clearColor];	
	authorLabel.lineBreakMode = UILineBreakModeTailTruncation;
	authorLabel.numberOfLines = 1;
	

	bookmarkButton = [UIButton buttonWithType:UIButtonTypeCustom];
	bookmarkButton.frame = CGRectMake(self.tableView.frame.size.width - 120.0 , runningYDispacement - 15, 50.0, 50.0);
	bookmarkButton.enabled = YES;
	[bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_off.png"] forState:UIControlStateNormal];
	[bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_off_pressed.png"] forState:(UIControlStateNormal | UIControlStateHighlighted)];
	[bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on.png"] forState:UIControlStateSelected];
	[bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on_pressed.png"] forState:(UIControlStateSelected | UIControlStateHighlighted)];
	[bookmarkButton addTarget:self action:@selector(bookmarkButtonToggled:) forControlEvents:UIControlEventTouchUpInside];
	
	bookmarkButtonIsOn = NO;
	
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"itemId == %@", libItem.itemId];
	LibraryItem *alreadyInDB = (LibraryItem *)[[CoreDataManager objectsForEntity:LibraryItemEntityName matchingPredicate:pred] lastObject];
	
	if (nil != alreadyInDB) {
		bookmarkButton.selected = [alreadyInDB.isBookmarked boolValue];
		bookmarkButtonIsOn = [alreadyInDB.isBookmarked boolValue];
	}
	
	mapButton = [UIButton buttonWithType:UIButtonTypeCustom];
	mapButton.frame = CGRectMake(self.tableView.frame.size.width - 60.0 , runningYDispacement - 15, 50.0, 50.0);
	mapButton.enabled = YES;
	[mapButton setImage:[UIImage imageNamed:@"global/map-it.png"] forState:UIControlStateNormal];
	[mapButton setImage:[UIImage imageNamed:@"global/map-it-pressed.png"] forState:(UIControlStateNormal | UIControlStateHighlighted)];
	[mapButton setImage:[UIImage imageNamed:@"global/map-it.png-pressed"] forState:UIControlStateSelected];
	[mapButton setImage:[UIImage imageNamed:@"global/map-it.png-pressed"] forState:(UIControlStateSelected | UIControlStateHighlighted)];
	[mapButton addTarget:self action:@selector(mapButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	
	UILabel *detailLabel1;
	UILabel *detailLabel2;
	UILabel *detailLabel3;
	
	if ([otherDetailLine1 length] > 0) {
		CGFloat detailHeight1 = [otherDetailLine1
								 sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
								 constrainedToSize:CGSizeMake(190, 20)         
								 lineBreakMode:UILineBreakModeWordWrap].height;
		
		detailLabel1 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 20 + runningYDispacement, 190.0, detailHeight1)];
		
		runningYDispacement += detailHeight1;
		
		detailLabel1.text = otherDetailLine1;
		detailLabel1.font = [UIFont fontWithName:STANDARD_FONT size:13];
		detailLabel1.textColor = [UIColor colorWithHexString:@"#554C41"];
		detailLabel1.backgroundColor = [UIColor clearColor];	
		detailLabel1.lineBreakMode = UILineBreakModeTailTruncation;
		detailLabel1.numberOfLines = 1;
	}
	
	if ([otherDetailLine2 length] > 0) {
		CGFloat detailHeight2 = [otherDetailLine2
								 sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
								 constrainedToSize:CGSizeMake(190, 20)         
								 lineBreakMode:UILineBreakModeWordWrap].height;
		
		detailLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 20 + runningYDispacement, 190.0, detailHeight2)];
		
		runningYDispacement += detailHeight2;
		
		detailLabel2.text = otherDetailLine2;
		detailLabel2.font = [UIFont fontWithName:STANDARD_FONT size:13];
		detailLabel2.textColor = [UIColor colorWithHexString:@"#554C41"];
		detailLabel2.backgroundColor = [UIColor clearColor];	
		detailLabel2.lineBreakMode = UILineBreakModeTailTruncation;
		detailLabel2.numberOfLines = 1;
	}
	
	if([otherDetailLine3 length] > 0) {
		CGFloat detailHeight3 = [otherDetailLine3
								 sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
								 constrainedToSize:CGSizeMake(190, 20)         
								 lineBreakMode:UILineBreakModeWordWrap].height;
		
		detailLabel3 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 20 + runningYDispacement, 190.0, detailHeight3)];
		
		runningYDispacement += detailHeight3;
		
		detailLabel3.text = otherDetailLine3;
		detailLabel3.font = [UIFont fontWithName:STANDARD_FONT size:13];
		detailLabel3.textColor = [UIColor colorWithHexString:@"#554C41"];
		detailLabel3.backgroundColor = [UIColor clearColor];	
		detailLabel3.lineBreakMode = UILineBreakModeTailTruncation;
		detailLabel3.numberOfLines = 1;
	}
	
	
	UIView * headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 
																   15 + runningYDispacement)];
	
	[headerView addSubview:titleLabel];
	[headerView addSubview:authorLabel];
	[headerView addSubview:authorButton];
	[headerView addSubview:bookmarkButton];
	[headerView addSubview:mapButton];
	
	if ([otherDetailLine1 length] > 0)
		[headerView addSubview:detailLabel1];
	
	if ([otherDetailLine2 length] > 0)
		[headerView addSubview:detailLabel2];
	
	if ([otherDetailLine3 length] > 0)
		[headerView addSubview:detailLabel3];
	
	self.tableView.tableHeaderView = [[UIView alloc]
									  initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, headerView.frame.size.height + 10)];
	[self.tableView.tableHeaderView addSubview:headerView];
	
	[self.tableView applyStandardColors];
}


#pragma mark User Interaction

-(void) authorLinkTapped:(id)sender{
	NSArray *viewControllerArray = [self.navigationController viewControllers];
	NSUInteger parentViewControllerIndex = [viewControllerArray count] - 2;
	NSLog(@"Parent view controller: %@", [viewControllerArray objectAtIndex:parentViewControllerIndex]);
	NSLog(@"Total vc: %d", [viewControllerArray count]);
	
	if ([sender isKindOfClass:[UIButton class]]){
		
		if ((nil != author) && ([author length] > 0)){
			
			LibrariesSearchViewController *vc = [[LibrariesSearchViewController alloc] initWithViewController: nil];
			vc.title = @"Search Results";
			
			apiRequest = [JSONAPIRequest requestWithJSONAPIDelegate:vc];
			BOOL requestWasDispatched = [apiRequest requestObjectFromModule:@"libraries"
														command:@"search"
													 parameters:[NSDictionary dictionaryWithObjectsAndKeys:author, @"q", nil]];
			
			if (requestWasDispatched) {
				vc.searchTerms = author;
				
				// break the navigation stack and only have the springboard, library-home and the next vc
				UIViewController * rootVC = [[self.navigationController viewControllers] objectAtIndex:0];
				UIViewController * nextVC = [[self.navigationController viewControllers] objectAtIndex:1];
				
				NSArray *controllersArray = [NSArray arrayWithObjects: rootVC, nextVC, vc,nil];
				
				[self.navigationController setViewControllers:controllersArray animated:YES];
				
			} else {
				//[self handleWarningMessage:@"Could not dispatch search" title:@"Search Failed"];
			}
			
			[vc release];
		}
	}
}


-(void) showNextLibItem: (id) sender {
	
	if ([sender isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl *theControl = (UISegmentedControl *)sender;
        NSInteger index = theControl.selectedSegmentIndex;
		
		if ([[libItemDictionary allKeys] count] > 1) {
			int tempLibIndex;
			
			if (index == 0) { // going up
				
				tempLibIndex = currentIndex - 1;
			}
			else
				tempLibIndex = currentIndex + 1;
			
			
			if ((tempLibIndex >= 0) && (tempLibIndex < [[libItemDictionary allKeys] count])){
				
				LibraryItem * temp = (LibraryItem *)[libItemDictionary objectForKey:[NSString stringWithFormat:@"%d", tempLibIndex +1]];
	
				apiRequest = [[JSONAPIRequest alloc] initWithJSONAPIDelegate:self];
				
				if ([apiRequest requestObjectFromModule:@"libraries" 
												command:@"fullavailability"
											 parameters:[NSDictionary dictionaryWithObjectsAndKeys:temp.itemId, @"itemid", nil]])
				{
					currentIndex = tempLibIndex;
					libItem = [temp retain];
					
					locationsWithItem = [[NSArray alloc] init];
					[self.tableView reloadData];
					[self setUpdetails:libItem];
					[self viewWillAppear:YES];
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

-(void) mapButtonPressed: (id) sender {
	
	
	if ([[displayNameAndLibraries allKeys] count] > 0) {
		LibraryLocationsMapViewController * vc = [[LibraryLocationsMapViewController alloc] initWithMapViewFrame:self.view.frame];
	
		[vc setAllAvailabilityLibraryLocations:displayNameAndLibraries];
		vc.navController = self;
		
		vc.title = @"Locations with Item";
		
		[self.navigationController pushViewController:vc animated:YES];
		[vc release];
	 }
	
}


-(void) bookmarkButtonToggled: (id) sender {
	
	
	BOOL newBookmarkButtonStatus = !bookmarkButton.selected;
	
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"itemId == %@",libItem.itemId];
	LibraryItem *alreadyInDB = (LibraryItem *)[[CoreDataManager objectsForEntity:LibraryItemEntityName matchingPredicate:pred] lastObject];
	
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

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    
	if (section == 0)
		return 1;
	
	else if (section == 1){
		if ([locationsWithItem count] == 0)
			return 1;
		
		return [locationsWithItem count];
	}
	
	return 0;
		
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	
	if (indexPath.section == 0) {
		
		
		static NSString *CellIdentifier = @"CellDet";
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		}
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
		
		BOOL val = [libItem.isOnline boolValue];
		if (val == YES) {
			cell.textLabel.text = @"Available Online";
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		else {
			cell.textLabel.text = @"Not Available Online";
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}

		
		
		return cell;
	}
	
	else if (indexPath.section == 1) {
	/*	NSDictionary * temp = [[NSDictionary alloc] initWithObjectsAndKeys:
		 @"available", @"1 of 2 available - regular loan",
		 @"unavailable", @"2 of 2 available - in-library user",
		 @"request", @"2 of 2 availavle - depository", nil];
	 */
		 
		
		if ([locationsWithItem count] == 0){
			static NSString *CellIdentifier = @"CellDetsfdsf";
			
			UITableViewCell *cell4 = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell4 == nil) {
				cell4 = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			}
			
			cell4.textLabel.text = @"data unavailable";
			cell4.selectionStyle = UITableViewCellSelectionStyleNone;
			
			[self addLoadingIndicator:cell4];
			return cell4;
			
		}
		NSDictionary * tempDict = [locationsWithItem objectAtIndex:indexPath.row];	
		
		NSDictionary * libraryDictionary  = [tempDict objectForKey:@"details"];;
		NSNumber * latitude = [libraryDictionary objectForKey:@"latitude"];
		NSNumber * longitude = [libraryDictionary objectForKey:@"longitude"];
		
		NSString * libName = [tempDict objectForKey:@"name"];
		
		
		NSArray * itemsByStat = (NSArray *)[tempDict objectForKey:@"itemsByStat"];
		
		NSMutableDictionary * dictWithStatuses = [[NSMutableDictionary alloc] init];
		
		if ([itemsByStat count] == 0)
			[dictWithStatuses setObject:@"unavailable" forKey:@"none available"];
		
		for(NSDictionary * statDict in itemsByStat) {
			
			NSString * statMain = [statDict objectForKey:@"statMain"];
			
			int availCount = 0;
			availCount = [[statDict objectForKey:@"availCount"] intValue];
			
			int unavailCount = 0;
			unavailCount = [[statDict objectForKey:@"unavailCount"] intValue];
			
			int checkedOutCount = 0;
			checkedOutCount = [[statDict objectForKey:@"checkedOutCount"] intValue];
			
			int requestCount = 0;
			requestCount = [[statDict objectForKey:@"requestCount"] intValue];
			
			int collectionOnlyCount = 0;
			collectionOnlyCount = [[statDict objectForKey:@"collectionOnlyCount"] intValue];
			
			int totalItems = availCount + unavailCount + checkedOutCount;
			
			
			NSArray * availableItems = (NSArray *)[statDict objectForKey:@"availableItems"];
				
			BOOL availableIsYellow = NO;
			for(NSDictionary * availItemDict in availableItems){
				
				NSString * canRequest = [availItemDict objectForKey:@"canRequest"];
				
				if ([canRequest isEqualToString:@"YES"]) {
					availableIsYellow = YES;
					break;
				}
			}
			
			NSString * status;
			
			if ((availCount > 0) && (availableIsYellow == NO))
				status = @"available";
			
			else if ((availCount > 0) && (availableIsYellow == YES))
				status = @"available";
			
			else if (checkedOutCount > 0)
				status = @"request";
			
			else if (unavailCount > 0)
				status = @"unavailable";
			
			else if (requestCount > 0)
				status = @"request";
			
			else {
				status = @"unavailable";
			}
			
			NSString * statusDetailString = [NSString stringWithFormat:
											 @"%d of %d available - %@", availCount, totalItems, statMain];
			
			if ((totalItems == 0) && (requestCount == 0))
				statusDetailString = [NSString stringWithFormat:
									  @"None available"];
			
			if (collectionOnlyCount > 0)
				statusDetailString = [NSString stringWithFormat:
									  @"0 of %d may be available", collectionOnlyCount];
				
			[dictWithStatuses setObject:status forKey:statusDetailString];
		}
		
		
		
		static NSString *CellIdentifier1 = @"CellLib";
		
		LibItemDetailCell *cell1 = (LibItemDetailCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
		
		if (nil != cell1)
			cell1 = nil;
		
		if (cell1 == nil) {
			cell1 = [[[LibItemDetailCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
											 reuseIdentifier:CellIdentifier1 
											itemAvailability:[dictWithStatuses retain]] autorelease];
		}
		

		
		cell1.textLabel.text = libName;
		
		
		CLLocation * libLoc = [[CLLocation alloc] initWithLatitude:[latitude doubleValue] longitude:[longitude doubleValue]];
		if ((nil != currentLocation) && (nil != libLoc)){

			float dist = [currentLocation distanceFromLocation:libLoc];
			cell1.detailTextLabel.text = [NSString stringWithFormat:@"%d meters away", dist];
		}
		else {
			cell1.detailTextLabel.text = @"Distance unavailable";
		}

 
		
		cell1.detailTextLabel.textColor = [UIColor colorWithHexString:@"#554C41"];
		
		if ([itemsByStat count] == 0)
			cell1.accessoryType = UITableViewCellAccessoryNone;
		
		else
			cell1.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
		cell1.selectionStyle = UITableViewCellSelectionStyleGray;
		
		return cell1;
		
	}
    
    // Configure the cell...
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{	
	UITableViewCellAccessoryType accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	NSString *cellText; 
	NSString *detailText;
	
	UIFont *detailFont = [UIFont systemFontOfSize:13];
	
	
	if (indexPath.section == 0) {
		cellText = @"Available Online";
		detailText = @"";
		accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else if ((indexPath.section == 1) && ([locationsWithItem count] > 0)){
		NSDictionary * tempDict = [locationsWithItem objectAtIndex:indexPath.row];		
		NSString * libName = [tempDict objectForKey:@"name"];
		cellText =  libName;
		detailText = @"xxx yards away";
		accessoryType = UITableViewCellAccessoryDisclosureIndicator;		
	}
	else if ((indexPath.section == 1) && ([locationsWithItem count] == 0)){
		cellText =  @"loading...";
		detailText = @"";
	}
	
	CGFloat height = [cellText
					  sizeWithFont:[UIFont fontWithName:COURSE_NUMBER_FONT size:COURSE_NUMBER_FONT_SIZE]
					  constrainedToSize:CGSizeMake(self.tableView.frame.size.width*2/3, 500)         
					  lineBreakMode:UILineBreakModeWordWrap].height;
	
	/*NSDictionary * tempDict = [[NSDictionary alloc] initWithObjectsAndKeys:
							   @"available", @"1 of 2 available - regular loan",
							   @"unavailable", @"2 of 2 available - in-library user",
							   @"request", @"2 of 2 availavle - depository", nil];
	 */
	
	if ((indexPath.section == 1) && ([locationsWithItem count] > 0)){

		
		NSDictionary * tempDict = [locationsWithItem objectAtIndex:indexPath.row];		
		
		NSArray * itemsByStat = (NSArray *)[tempDict objectForKey:@"itemsByStat"];
		
		NSMutableDictionary * dictWithStatuses = [[NSMutableDictionary alloc] init];
		
		if ([itemsByStat count] == 0)
			[dictWithStatuses setObject:@"unavailable" forKey:@"none available"];
		
		for(NSDictionary * statDict in itemsByStat) {
			
			NSString * statMain = [statDict objectForKey:@"statMain"];
			
			int availCount = 0;
			availCount = [[statDict objectForKey:@"availCount"] intValue];
			
			int unavailCount = 0;
			unavailCount = [[statDict objectForKey:@"unavailCount"] intValue];
			
			int checkedOutCount = 0;
			checkedOutCount = [[statDict objectForKey:@"checkedOutCount"] intValue];
			
			int requestCount = 0;
			requestCount = [[statDict objectForKey:@"requestCount"] intValue];
			
			int totalItems = availCount + unavailCount + checkedOutCount;
			
			
			NSArray * availableItems = (NSArray *)[statDict objectForKey:@"availableItems"];
			
			BOOL availableIsYellow = NO;
			for(NSDictionary * availItemDict in availableItems){
				
				NSString * canRequest = [availItemDict objectForKey:@"canRequest"];
				
				if ([canRequest isEqualToString:@"YES"]) {
					availableIsYellow = YES;
					break;
				}
			}
			
			NSString * status;
			
			if ((availCount > 0) && (availableIsYellow == NO))
				status = @"available";
			
			else if ((availCount > 0) && (availableIsYellow == YES))
				status = @"request";
			
			else if (requestCount > 0)
				status = @"request";
			
			else {
				status = @"unavailable";
			}
			
			NSString * statusDetailString = [NSString stringWithFormat:
											 @"%d of %d available - %@", availCount, totalItems, statMain];
			
			[dictWithStatuses setObject:status forKey:statusDetailString];
		}
		
		
		
	return [LibItemDetailCell heightForCellWithStyle:UITableViewCellStyleSubtitle
												tableView:tableView 
													 text:cellText
											 maxTextLines:2
											   detailText:detailText
										   maxDetailLines:1
													 font:nil 
											   detailFont:detailFont
											accessoryType:accessoryType
												cellImage:YES
						  itemAvailabilityDictionary: dictWithStatuses];
	}
	
	return height + 20;

}



#pragma mark -
#pragma mark Table view delegate
- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
	if (indexPath.section == 0){
		
		BOOL val = [libItem.isOnline boolValue];
		if (val == YES) {
			
			NSString *url = libItem.onlineLink;
			
			NSURL *libURL = [NSURL URLWithString:url];
			if (libURL && [[UIApplication sharedApplication] canOpenURL:libURL]) {
				[[UIApplication sharedApplication] openURL:libURL];
			}
		}
	}
	
	
	if ([locationsWithItem count] > 0) {
		
		NSDictionary * tempDict = [locationsWithItem objectAtIndex:indexPath.row];		
		NSString * libName = [tempDict objectForKey:@"name"];
		NSString * libId = [tempDict objectForKey:@"id"];
		NSString * type = [tempDict objectForKey:@"type"];
		
		NSString * primaryName = [((NSDictionary *)[tempDict objectForKey:@"details"]) objectForKey:@"primaryName"];

		
		NSArray * itemsByStat = (NSArray *)[tempDict objectForKey:@"itemsByStat"];
	
	
		if (([itemsByStat count] > 0) && (indexPath.section == 1)) {
			ItemAvailabilityDetailViewController * vc = [[ItemAvailabilityDetailViewController alloc]
														 initWithStyle:UITableViewStyleGrouped
														 libName: libName
														primName: primaryName
														 libId: libId
														 libType: type
														 item:libItem
														 categories:itemsByStat
														 allLibrariesWithItem:locationsWithItem
														 index:indexPath.row];
			
			
			apiRequest = [[JSONAPIRequest alloc] initWithJSONAPIDelegate:vc];
			vc.parentViewApiRequest = [apiRequest retain];
			
			NSString * libOrArchive;
			if ([type isEqualToString:@"archive"])
				libOrArchive = @"archivedetail";
			
			else {
				libOrArchive = @"libdetail";
			}
			
			
			if ([apiRequest requestObjectFromModule:@"libraries" 
											command:libOrArchive
										 parameters:[NSDictionary dictionaryWithObjectsAndKeys:libId, @"id", libName, @"name", nil]])
			{
				
			}
			else {
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
																	message:@"Could not retrieve today's hours" 
																   delegate:self 
														  cancelButtonTitle:@"OK" 
														  otherButtonTitles:nil];
				[alertView show];
				[alertView release];
			}
			
			[vc release];
			
			
			
			vc.title = @"Availability";
			[self.navigationController pushViewController:vc animated:YES];
			[vc release];
		}
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
	locationManager.delegate = nil;
	[locationManager release];
}


- (void)dealloc {
    [super dealloc];
	locationManager.delegate = nil;
	[locationManager release];
	
}


#pragma mark -
#pragma mark JSONAPIRequest Delegate function 

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result {
	
	if ([result isKindOfClass:[NSArray class]]) {
		
		locationsWithItem = [result retain];
		[self.tableView reloadData];
		
		displayNameAndLibraries = [[NSMutableDictionary alloc] init];
		
		for(NSDictionary * tempDict in result) {
			
			NSDictionary * libraryDictionary  = [tempDict objectForKey:@"details"];
			NSString * displayName = [tempDict objectForKey:@"name"];
			
			if ((nil != libraryDictionary) && (![libraryDictionary isKindOfClass:[NSArray class]]))
		     if ([[libraryDictionary allKeys] count] > 0) {
				NSString * name = [libraryDictionary objectForKey:@"name"];
				NSString * primaryName = [libraryDictionary objectForKey:@"primaryName"];
				NSString * type = [libraryDictionary objectForKey:@"type"];
				NSString * identityTag = [libraryDictionary objectForKey:@"id"];
				//NSString *directions = [libraryDictionary objectForKey:@"directions"];
				NSString * location = [libraryDictionary objectForKey:@"address"];
				NSNumber * latitude = [libraryDictionary objectForKey:@"latitude"];
				NSNumber * longitude = [libraryDictionary objectForKey:@"longitude"];
				
				NSPredicate *pred = [NSPredicate predicateWithFormat:@"name == %@ AND type == %@", name, type];
				Library *alreadyInDB = [[CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:pred] lastObject];
				
				
				NSManagedObject *managedObj;
				if (nil == alreadyInDB){
					managedObj = [CoreDataManager insertNewObjectForEntityForName:LibraryEntityName];
					alreadyInDB = (Library *)managedObj;
					alreadyInDB.isBookmarked = [NSNumber numberWithBool:NO];
				}
				
				alreadyInDB.name = name;
				alreadyInDB.primaryName = primaryName;
				alreadyInDB.identityTag = identityTag;
				alreadyInDB.location = location;
				alreadyInDB.lat = [NSNumber numberWithDouble:[latitude doubleValue]];
				alreadyInDB.lon = [NSNumber numberWithDouble:[longitude doubleValue]];
				alreadyInDB.type = type;
				
				alreadyInDB.isBookmarked = alreadyInDB.isBookmarked;
				
				[displayNameAndLibraries setObject:alreadyInDB forKey:displayName];
				
				[CoreDataManager saveData];
			}
		}
		
		
		locationManager = [[CLLocationManager alloc] init];
		locationManager.distanceFilter = kCLDistanceFilterNone;
		locationManager.desiredAccuracy = kCLLocationAccuracyBest;
		locationManager.delegate = self;

		[locationManager startUpdatingLocation];
			
		}
	else {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
														message:@"Could not retrieve item availability" 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
		[alertView show];
		[alertView release];
	}
	
	[self removeLoadingIndicator];
}

- (BOOL)request:(JSONAPIRequest *)request shouldDisplayAlertForError:(NSError *)error {
	
    return YES;
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error {
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
														message:@"Could not retrieve item availability" 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
	[alertView show];
	[alertView release];
	[self removeLoadingIndicator];
}


#pragma mark loading-indicator
- (void)addLoadingIndicator:(UIView *)view
{
	if (loadingIndicator == nil) {
		static NSString *loadingString = @"Checking availability...";
		UIFont *loadingFont = [UIFont fontWithName:STANDARD_FONT size:17.0];
		CGSize stringSize = [loadingString sizeWithFont:loadingFont];
		
        CGFloat verticalPadding = view.frame.size.height/2 - 5;
        CGFloat horizontalPadding = 5.0; //view.frame.size.width/2 - 50;
        CGFloat horizontalSpacing = 15.0;
		// CGFloat cornerRadius = 8.0;
        
        UIActivityIndicatorViewStyle style = UIActivityIndicatorViewStyleGray;
		UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
		// spinny.center = CGPointMake(spinny.center.x + horizontalPadding, spinny.center.y + verticalPadding);
		spinny.center = CGPointMake(horizontalPadding, verticalPadding);
		[spinny startAnimating];
        
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(horizontalPadding + horizontalSpacing, verticalPadding -10, stringSize.width, stringSize.height + 2.0)];
		label.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
		label.text = loadingString;
		label.font = loadingFont;
		label.backgroundColor = [UIColor clearColor];
        
		//loadingIndicator = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, stringSize.width + spinny.frame.size.width + horizontalPadding * 2, stringSize.height + verticalPadding * 2)];
		loadingIndicator = [[UIView alloc] initWithFrame:CGRectMake(20.0, 5.0, view.frame.size.width/2 - 20, 0.8*view.frame.size.height - 5)];
		//loadingIndicator = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300, 300)];
        //loadingIndicator.layer.cornerRadius = cornerRadius;
        //loadingIndicator.backgroundColor =[UIColor whiteColor];
		
		[loadingIndicator setBackgroundColor:[UIColor whiteColor]];
		[loadingIndicator addSubview:spinny];
		[spinny release];
		[loadingIndicator addSubview:label];
		[label release];
		
	}
	
	
	[view addSubview:loadingIndicator];
}

- (void)removeLoadingIndicator
{
	[loadingIndicator removeFromSuperview];
	[loadingIndicator release];
	loadingIndicator = nil;
	
}


#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
	
    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 120.0) return;
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0) return;
  
	currentLocation = [newLocation retain];
	[locationManager stopUpdatingLocation];
	[self.tableView reloadData];

}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error{
	
	currentLocation = nil;
	[locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
	currentLocation = nil;
	[locationManager stopUpdatingLocation];
	
}

@end

