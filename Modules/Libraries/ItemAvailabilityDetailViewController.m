//
//  ItemAvailabilityDetailViewController.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 12/6/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "ItemAvailabilityDetailViewController.h"
#import "MITUIConstants.h"
#import "RequestWebViewModalViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "ItemAvailabilityLibDetailViewController.h"
#import "CoreDataManager.h"
#import "LibrariesMultiLineCell.h"


@implementation ItemAvailabilityDetailViewController
@synthesize parentViewApiRequest;


#pragma mark -
#pragma mark Initialization


- (id)initWithStyle:(UITableViewStyle)style 
			libName:(NSString *)libName
		   primName:(NSString *)primName
			  libId:(NSString *) libId
			libType: (NSString *) libType
			   item:(LibraryItem *)libraryItem 
		 categories:(NSArray *)availCategories
allLibrariesWithItem: (NSArray *) allLibraries
			 index :(int) index{
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
		
		libraryName = libName;
		libraryId = libId;
		primaryName = primName;
		type = libType;
		libItem = [libraryItem retain];
		availabilityCategories  = [availCategories retain];
		arrayWithAllLibraries = [allLibraries retain];
		currentIndex = index;
    }
    return self;
}


#pragma mark -
#pragma mark View lifecycle


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
	
	if (currentIndex == 0)
		[segmentControl setEnabled:NO forSegmentAtIndex:0];
	
	if (currentIndex == [arrayWithAllLibraries count] - 1)
		[segmentControl setEnabled:NO forSegmentAtIndex:1];
	
	[segmentControl release];
	[segmentBarItem release];
	
	
	headerView = nil; 

	NSString * nameToDisplay = libraryName;
	
	if ((![libraryName isEqualToString:primaryName]) && ([primaryName length] > 0))
		nameToDisplay = [NSString stringWithFormat:@"%@ (%@)", libraryName, primaryName];
						 
	CGFloat height1 = [nameToDisplay
					  sizeWithFont:[UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE]
					  constrainedToSize:CGSizeMake(250, 2000)         
					   lineBreakMode:UILineBreakModeWordWrap].height;
						
	CGFloat height2 = [openToday
					 sizeWithFont:[UIFont fontWithName:COURSE_NUMBER_FONT size:13]
					 constrainedToSize:CGSizeMake(250, 20)         
					 lineBreakMode:UILineBreakModeWordWrap].height;
	
	CGFloat height = height1 + height2;
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 9.0, 250, height1)];

	height1 += 9.0;
	
	label.text = nameToDisplay;	
	label.font = [UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE];
	label.textColor = [UIColor colorWithHexString:@"#1a1611"];
	label.backgroundColor = [UIColor clearColor];	
	label.lineBreakMode = UILineBreakModeWordWrap;
	label.numberOfLines = 10;
	
	NSString * openTodayString;
	if (nil == openToday)
		openTodayString = @"";
	else {
		openTodayString = openToday;
	}

	
	UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, height1, 250, height2)];
	label2.text = openTodayString;
	label2.font = [UIFont fontWithName:COURSE_NUMBER_FONT
								  size:13];
	label2.textColor = [UIColor colorWithHexString:@"#666666"];
	label2.backgroundColor = [UIColor clearColor];	
	label2.lineBreakMode = UILineBreakModeWordWrap;
	label2.numberOfLines = 1;
	
	
	infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
	infoButton.frame = CGRectMake(self.tableView.frame.size.width - 55.0 , 5, 50.0, 50.0);
	infoButton.enabled = YES;
	[infoButton setImage:[UIImage imageNamed:@"global/info_button.png"] forState:UIControlStateNormal];
	[infoButton setImage:[UIImage imageNamed:@"global/info_button_pressed.png"] forState:(UIControlStateNormal | UIControlStateHighlighted)];
	[infoButton setImage:[UIImage imageNamed:@"global/info_button_pressed.png"] forState:UIControlStateSelected];
	[infoButton setImage:[UIImage imageNamed:@"global/info_button_pressed.png"] forState:(UIControlStateSelected | UIControlStateHighlighted)];
	[infoButton addTarget:self action:@selector(infoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	
	
	if (height < 50)
		height = 50;
	
	headerView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.frame.size.width, height + 5.0)] autorelease];
	[headerView addSubview:label];
	[headerView addSubview:label2];
	[headerView addSubview:infoButton];
	
	self.tableView.tableHeaderView = [[UIView alloc]
									  initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, headerView.frame.size.height + 5)];
	[self.tableView.tableHeaderView addSubview:headerView];
	
	[self.tableView applyStandardColors];
	
	[label2 release];
	[label release];
	
	
	sectionType = [[NSMutableDictionary alloc] init];
	
	for (int section=0; section < [availabilityCategories count]; section++) {
		
		BOOL isTypeOne = NO;
		BOOL isTypeTwo = NO;
		
		NSDictionary * statDict = [availabilityCategories objectAtIndex:section];
		
		int collectionOnlyCount = 0;
		collectionOnlyCount = [[statDict objectForKey:@"collectionOnlyCount"] intValue];
		
		if (collectionOnlyCount > 0)
			isTypeTwo = YES;
		
		
		if (isTypeTwo == NO) {
			
			NSMutableArray * items = [[NSMutableArray alloc] init];
			int indexCount =0;
			
			NSArray * availableItems = (NSArray *)[statDict objectForKey:@"availableItems"];
			NSArray * checkedOutItems = (NSArray * )[statDict objectForKey:@"checkedOutItems"];
			
			for(NSDictionary * item in availableItems) {
				[items insertObject:item atIndex:indexCount];
				indexCount++;
			}
			
			for(NSDictionary * item1 in checkedOutItems) {
				[items insertObject:item1 atIndex:indexCount];
				indexCount++;
			}
			
			for(NSDictionary * availItemDict in items){
				
				NSString * firstCallNbr = [[items objectAtIndex:0] objectForKey:@"callNumber"];
				NSString * callNbr = [availItemDict objectForKey:@"callNumber"];
				
				
				if (![firstCallNbr isEqualToString:callNbr]){
					[sectionType setObject:sectionType1 forKey:[NSString stringWithFormat:@"%d",section]];
					isTypeOne = YES;
					break;
				}
			}
			
			if ((isTypeOne == NO) && (isTypeTwo == NO))
				[sectionType setObject:sectionType0 forKey:[NSString stringWithFormat:@"%d",section]];
			
		}
		
		else if (isTypeTwo == YES)
			[sectionType setObject:sectionType0 forKey:[NSString stringWithFormat:@"%d",section]];
		
	}
	
	limitedView = YES;
}




- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	[self setupLayout];
}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self setupLayout];
	[self.tableView reloadData];
}



#pragma mark User Interaction


-(void)infoButtonPressed: (id) sender {
	
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"name == %@ AND type == %@", primaryName, type];
	Library *alreadyInDB = [[CoreDataManager objectsForEntity:LibraryEntityName matchingPredicate:pred] lastObject];
	
	
	NSManagedObject *managedObj;
	if (nil == alreadyInDB){
		managedObj = [CoreDataManager insertNewObjectForEntityForName:LibraryEntityName];
		alreadyInDB = (Library *)managedObj;
		alreadyInDB.isBookmarked = [NSNumber numberWithBool:NO];
		alreadyInDB.name = primaryName;
		alreadyInDB.primaryName = primaryName;
	}
	
	ItemAvailabilityLibDetailViewController *vc = [[ItemAvailabilityLibDetailViewController alloc]
												   initWithStyle:UITableViewStyleGrouped
												   displayName:libraryName
												   currentInd:0
												   library:(Library *)alreadyInDB
												   otherLibDictionary:[[NSDictionary alloc] init]];
	
	apiRequest = [[JSONAPIRequest alloc] initWithJSONAPIDelegate:vc];
	
	NSString * libOrArchive;
	
	if ([type isEqualToString:@"archive"]) {
		vc.title = @"Archive Detail";
		libOrArchive = @"archivedetail";
	}
	
	else {
		vc.title = @"Library Detail";
		libOrArchive = @"libdetail";
	}
	
	
	if ([apiRequest requestObjectFromModule:@"libraries" 
									command:libOrArchive
								 parameters:[NSDictionary dictionaryWithObjectsAndKeys:libraryId, @"id", libraryName, @"name", nil]])
	{
		[self.navigationController pushViewController:vc animated:YES];
	}
	else {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
															message:NSLocalizedString(@"Could not connect to server", nil)
														   delegate:self 
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil];
		[alertView show];
		[alertView release];
	}
	
	[vc release];
}
	

-(void) showNextLibrary: (id) sender {
	
	if ([sender isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl *theControl = (UISegmentedControl *)sender;
        NSInteger index = theControl.selectedSegmentIndex;
		
		if ([arrayWithAllLibraries count] > 1) {
			int tempLibIndex;
			
			if (index == 0) { // going up
				
				tempLibIndex = currentIndex - 1;
			}
			else
				tempLibIndex = currentIndex + 1;
			
			
			if ((tempLibIndex >= 0) && (tempLibIndex < [arrayWithAllLibraries count])){
				
				NSDictionary * tempDict = [arrayWithAllLibraries objectAtIndex:tempLibIndex];		
				NSString * libName = [tempDict objectForKey:@"name"];
				NSString * libId = [tempDict objectForKey:@"id"];
				NSString * typeTemp = [tempDict objectForKey:@"type"];
				
				NSString * primaryNameTemp = [((NSDictionary *)[tempDict objectForKey:@"details"]) objectForKey:@"primaryName"];
				
				NSArray * collections = (NSArray *)[tempDict objectForKey:@"collection"];
					
					apiRequest = [[JSONAPIRequest alloc] initWithJSONAPIDelegate:self];
					
					NSString * libOrArchive;
					if ([typeTemp isEqualToString:@"archive"])
						libOrArchive = @"archivedetail";
					
					else {
						libOrArchive = @"libdetail";
					}
					
					
					if ([apiRequest requestObjectFromModule:@"libraries" 
													command:libOrArchive
												 parameters:[NSDictionary dictionaryWithObjectsAndKeys:libId, @"id", libName, @"name", nil]])
					{
					
						currentIndex = tempLibIndex;
						libraryName = libName;
						primaryName = primaryNameTemp;
						libraryId = libId;
						type = typeTemp;
						availabilityCategories = collections;
						[self viewWillAppear:YES];		
					}
					else {
						UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Failed", nil)
																			message:NSLocalizedString(@"Could not retrieve item-availability", nil)
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



-(UITableViewCell *) sectionTypeONE:(NSIndexPath *)indexPath tableView:(UITableView *)tableView{
	
	static NSString *CellIdentifier = @"CellTypeONE";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	NSDictionary * collection = [availabilityCategories objectAtIndex:indexPath.section];
	
	// type I has only one holding status per collection
	NSDictionary * statDict = (NSDictionary *)[((NSArray *)[collection objectForKey:@"itemsByStat"]) lastObject];
	
	int availCount = 0;
	availCount = [[statDict objectForKey:@"availCount"] intValue];
	
	int unavailCount = 0;
	unavailCount = [[statDict objectForKey:@"unavailCount"] intValue];
	
	int checkedOutCount = 0;
	checkedOutCount = [[statDict objectForKey:@"checkedOutCount"] intValue];
	
	int requestCount = 0;
	requestCount = [[statDict objectForKey:@"requestCount"] intValue];
	
	NSArray * availableItems = (NSArray *)[statDict objectForKey:@"availableItems"];
	NSArray * checkedOutItems = (NSArray * )[statDict objectForKey:@"checkedOutItems"];
	NSArray * unavailableItems = (NSArray * )[statDict objectForKey:@"unavailableItems"];
	
	BOOL availableIsYellow = NO;
	for(NSDictionary * availItemDict in availableItems){
		
		NSString * canRequest = [availItemDict objectForKey:@"canRequest"];
		NSString * canScanAndDeliver = [availItemDict objectForKey:@"canScanAndDeliver"];
		
		if (([canRequest isEqualToString:@"YES"]) || ([canScanAndDeliver isEqualToString:@"YES"])){
			availableIsYellow = YES;
			break;
		}
	}
	
	BOOL checkedOutCanRequest = NO;
	for(NSDictionary * availItemDict in checkedOutItems){
		
		NSString * canRequest = [availItemDict objectForKey:@"canRequest"];
		NSString * canScanAndDeliver = [availItemDict objectForKey:@"canScanAndDeliver"];
		
		if (([canRequest isEqualToString:@"YES"]) || ([canScanAndDeliver isEqualToString:@"YES"])){
			checkedOutCanRequest = YES;
			break;
		}
	}
	
	BOOL unavailableCanRequest = NO;
	for(NSDictionary * unavailItemDict in unavailableItems){
		
		NSString * canRequest = [unavailItemDict objectForKey:@"canRequest"];
		NSString * canScanAndDeliver = [unavailItemDict objectForKey:@"canScanAndDeliver"];
		
		if (([canRequest isEqualToString:@"YES"]) || ([canScanAndDeliver isEqualToString:@"YES"])){
			unavailableCanRequest = YES;
			break;
		}
	}

	
	if (indexPath.row == 0) {// available
		
		if (availCount > 0) {
			cell.textLabel.text = [NSString stringWithFormat:@"%d available", availCount];
			UIImage *image;
			if (availableIsYellow == YES) {
				//image = [UIImage imageNamed:@"dining/dining-status-open-w-restrictions.png"];
				//cell.imageView.image = image;
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				
				//[cell addSubview:label2];
			}
			
			//else {
			image = [UIImage imageNamed:@"dining/dining-status-open.png"];
			cell.imageView.image = image;
			//}
		}
		else if (checkedOutCount > 0){
			cell.textLabel.text = [NSString stringWithFormat:@"%d checked out", checkedOutCount];
			
			if (checkedOutCanRequest == YES) {
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				//[cell addSubview:label2];
			}
			
			UIImage *image = [UIImage imageNamed:@"dining/dining-status-open-w-restrictions.png"];
			cell.imageView.image = image;
			
			
		}
		
		else if (unavailCount > 0){
			
			if (unavailableCanRequest == YES)
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				
			cell.textLabel.text = [NSString stringWithFormat:@"%d unavailable", unavailCount];
			UIImage *image = [UIImage imageNamed:@"dining/dining-status-closed.png"];
			cell.imageView.image = image;
		}
		
		
	}
	
	else if (indexPath.row == 1) {// checked out
		if (checkedOutCount > 0){
			cell.textLabel.text = [NSString stringWithFormat:@"%d checked out", checkedOutCount];
			
			if (checkedOutCanRequest == YES) {
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				//[cell addSubview:label2];
			}
			
			UIImage *image = [UIImage imageNamed:@"dining/dining-status-open-w-restrictions.png"];
			cell.imageView.image = image;
			
			
		}
		
		else if (unavailCount > 0){
			if (unavailableCanRequest == YES)
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			
			cell.textLabel.text = [NSString stringWithFormat:@"%d unavailable", unavailCount];
			UIImage *image = [UIImage imageNamed:@"dining/dining-status-closed.png"];
			cell.imageView.image = image;
		}
		
	}
	
	else if (indexPath.row == 2) {// unavailable
		
		if (unavailCount > 0) {
			if (unavailableCanRequest == YES)
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			
			cell.textLabel.text = [NSString stringWithFormat:@"%d unavailable", unavailCount];
			UIImage *image = [UIImage imageNamed:@"dining/dining-status-closed.png"];
			cell.imageView.image = image;
		}
	}
	
	
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	
    return cell;
	
}


-(UITableViewCell *) sectionTypeTWO:(NSIndexPath *)indexPath tableView:(UITableView *)tableView{
	
	static NSString *CellIdentifier = @"CellTypeTWO";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
	int availRowCount = 0;
	int checkedOutRowCount = 0;
	int unavailRowCount = 0;
	
	
	int availRowMax = -1;
	int checkedOutRowMax = -1;
	int unavailRowMax = -1;
	
	NSDictionary * collection = [availabilityCategories objectAtIndex:indexPath.section];
	NSArray * stats = (NSArray *)[collection objectForKey:@"itemsByStat"];

	
	NSMutableArray * availItems = [[NSMutableArray alloc] init];
	NSMutableArray * checkedOutItems = [[NSMutableArray alloc] init];
	NSMutableArray * unavailItems = [[NSMutableArray alloc] init];
	
	for(NSDictionary * statDict in stats){
		
		NSArray * availableItemsTemp = (NSArray *)[statDict objectForKey:@"availableItems"];
		NSArray * checkedOutItemsTemp = (NSArray * )[statDict objectForKey:@"checkedOutItems"];
		NSArray * unavailableItemsTemp = (NSArray * )[statDict objectForKey:@"unavailableItems"];
		
		if ([availableItemsTemp count] > 0) {
			[availItems insertObject:availableItemsTemp atIndex:availRowCount];
			availRowCount++;
		}
		
		if ([checkedOutItemsTemp count] > 0){
			[checkedOutItems insertObject:checkedOutItemsTemp atIndex:checkedOutRowCount];
			checkedOutRowCount++;
		}
		
		for(NSDictionary * unavailDict in unavailableItemsTemp){
			[unavailItems insertObject:unavailDict atIndex:unavailRowCount];
			unavailRowCount++;
		}
		
	}
	
	availRowMax = availRowCount - 1;
	checkedOutRowMax = availRowMax + checkedOutRowCount;
	unavailRowMax = checkedOutRowMax++;
	
	NSString * status = @"";
	NSString * imagePath = @"";
	NSString * statMain = @"";
	NSArray * itemsForStatus = [[NSArray alloc] init];
	if (indexPath.row <= availRowMax){
		
		itemsForStatus = [availItems objectAtIndex:indexPath.row];
		status = @"available";
		imagePath = @"dining/dining-status-open.png";
	}
	
	else if (indexPath.row <= checkedOutRowMax){
		itemsForStatus = [checkedOutItems objectAtIndex:indexPath.row - checkedOutRowCount];
		status = @"checked out";
		imagePath = @"dining/dining-status-open-w-restrictions.png";
	}
	
	else if (indexPath.row == unavailRowMax){
		itemsForStatus = [unavailItems retain];
		status = @"unavailable";
		imagePath = @"dining/dining-status-closed.png";
	}
	
	statMain = [(NSDictionary *)[itemsForStatus lastObject] objectForKey:@"statMain"];
				
	BOOL canRequestItem = NO;
	for(NSDictionary * itemDict in itemsForStatus){
		
		NSString * canRequest = [itemDict objectForKey:@"canRequest"];
		NSString * canScanAndDeliver = [itemDict objectForKey:@"canScanAndDeliver"];
		
		if (([canRequest isEqualToString:@"YES"]) || ([canScanAndDeliver isEqualToString:@"YES"])){
			canRequestItem = YES;
			break;
		}
	}
		
	if (canRequestItem == YES)
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	UIImage * image = [UIImage imageNamed:imagePath];
	cell.imageView.image = image;
	
	cell.textLabel.text = [NSString stringWithFormat:@"%d %@", [itemsForStatus count], status];	
	cell.detailTextLabel.text = statMain;
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	
	return cell;
	
}


-(UITableViewCell *) sectionTypeFOUR:(NSIndexPath *)indexPath tableView:(UITableView *)tableView{
	
	static NSString *CellIdentifier = @"CellTypeTHREE";
    
    LibrariesMultiLineCell *cell = (LibrariesMultiLineCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[LibrariesMultiLineCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
	NSDictionary * collection = [availabilityCategories objectAtIndex:indexPath.section];
	NSArray * stats = (NSArray *)[collection objectForKey:@"itemsByStat"];
	
	NSMutableArray * items = [[NSMutableArray alloc] init];
	int indexCount =0;
	
	if ((limitedView == YES) && (indexPath.row >= 5)){
		cell.textLabel.text = @"      Show all items";
		cell.detailTextLabel.text = @"";
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.imageView.image = nil;
		return cell;
	}
	
	for(NSDictionary * statDict in stats) {
		NSArray * availableItems = (NSArray *)[statDict objectForKey:@"availableItems"];
		NSArray * checkedOutItems = (NSArray * )[statDict objectForKey:@"checkedOutItems"];
		NSArray * unavailableItems = (NSArray * )[statDict objectForKey:@"unavailableItems"];
		
		for(NSDictionary * item in availableItems) {
			[items insertObject:item atIndex:indexCount];
			indexCount++;
		}
		
		for(NSDictionary * item1 in checkedOutItems) {
			[items insertObject:item1 atIndex:indexCount];
			indexCount++;
		}
		
		for(NSDictionary * item2 in unavailableItems) {
			[items insertObject:item2 atIndex:indexCount];
			indexCount++;
		}
	}
	
	
	NSDictionary * itemForRow = [items objectAtIndex:indexPath.row];
	NSString * canRequest = [itemForRow objectForKey:@"canRequest"];
	NSString * canScanAndDeliver = [itemForRow objectForKey:@"canScanAndDeliver"];
	//NSString * isUnAvailable = [itemForRow objectForKey:@"unavailable"];
	NSString * isAvailable = [itemForRow objectForKey:@"available"];
	NSString * isCheckedOut = [itemForRow objectForKey:@"checkedOutItem"];
	
	NSString * status = @"";
	NSString * color = @"";
	
	if ([isAvailable isEqualToString:@"YES"]){
		status = @"Available";
		color = @"green";
	}
	
	else if ([isCheckedOut isEqualToString:@"YES"]){
		status = @"Checked Out";
		color = @"yellow";
	}
	
	else {
		status = @"Unavailable";
		color = @"gray";
	}

	NSString * callNumber = [itemForRow objectForKey:@"callNumber"];
	NSString * desc = [itemForRow objectForKey:@"description"];
	NSString * statMain = [itemForRow objectForKey:@"statMain"];
	callNumber = [NSString stringWithFormat:@"%@-%@\n%@", desc, callNumber, statMain];
	
	cell.textLabel.text = status;
	cell.detailTextLabel.textColor = [UIColor colorWithHexString:@"#554C41"];
	cell.detailTextLabel.font = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
	cell.detailTextLabel.numberOfLines = 4;
	cell.detailTextLabel.text = callNumber;
	
	if ([color isEqualToString:@"green"])
		cell.imageView.image = [UIImage imageNamed:@"dining/dining-status-open.png"];
	
	else if ([color isEqualToString:@"yellow"])
		cell.imageView.image = [UIImage imageNamed:@"dining/dining-status-open-w-restrictions.png"];
	
	else
		cell.imageView.image = [UIImage imageNamed:@"dining/dining-status-closed.png"];
	
	if (([canRequest isEqualToString:@"YES"]) || ([canScanAndDeliver isEqualToString:@"YES"]))
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	
    return cell;
	
}

-(UITableViewCell *) sectionTypeTHREE:(NSIndexPath *)indexPath tableView:(UITableView *)tableView{
	
	static NSString *CellIdentifier = @"CellTypeFOUR";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
	if ((limitedView == YES) && (indexPath.row >= 5)){
		cell.textLabel.text = @"      Show all items";
		cell.detailTextLabel.text = @"";
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.imageView.image = nil;
		return cell;
	}
	
	NSDictionary * collection = [availabilityCategories objectAtIndex:indexPath.section];
	NSArray * stats = (NSArray *)[collection objectForKey:@"itemsByStat"];
	
	NSMutableArray * items = [[NSMutableArray alloc] init];
	int indexCount =0;
	
	for(NSDictionary * statDict in stats) {
		NSArray * availableItems = (NSArray *)[statDict objectForKey:@"availableItems"];
		NSArray * checkedOutItems = (NSArray * )[statDict objectForKey:@"checkedOutItems"];
		NSArray * unavailableItems = (NSArray * )[statDict objectForKey:@"unavailableItems"];
		
		for(NSDictionary * item in availableItems) {
			[items insertObject:item atIndex:indexCount];
			indexCount++;
		}
		
		for(NSDictionary * item1 in checkedOutItems) {
			[items insertObject:item1 atIndex:indexCount];
			indexCount++;
		}
		
		for(NSDictionary * item2 in unavailableItems) {
			[items insertObject:item2 atIndex:indexCount];
			indexCount++;
		}
	}
	
	
	NSDictionary * itemForRow = [items objectAtIndex:indexPath.row];
	NSString * canRequest = [itemForRow objectForKey:@"canRequest"];
	NSString * canScanAndDeliver = [itemForRow objectForKey:@"canScanAndDeliver"];
	NSString * isUnAvailable = [itemForRow objectForKey:@"unavailable"];
	NSString * isAvailable = [itemForRow objectForKey:@"available"];
	NSString * isCheckedOut = [itemForRow objectForKey:@"checkedOutItem"];
	
	NSString * status = @"";
	NSString * color = @"";
	
	if ([isAvailable isEqualToString:@"YES"]){
		status = @"Available";
		color = @"green";
	}
	
	/*else if (([canRequest isEqualToString:@"YES"]) || ([canScanAndDeliver isEqualToString:@"YES"])) {
	 status = @"Checked Out";
	 color = @"yellow";
	 }*/
	
	else if ([isCheckedOut isEqualToString:@"YES"]){
		status = @"Checked Out";
		color = @"yellow";
	}
	
	else {
		status = @"Unavailable";
		color = @"gray";
	}
	
	NSString * callNumber = [itemForRow objectForKey:@"callNumber"];
	NSString * desc = [itemForRow objectForKey:@"description"];
	callNumber = [NSString stringWithFormat:@"%@-%@", desc, callNumber];
	
	cell.textLabel.text = status;
	cell.detailTextLabel.textColor = [UIColor colorWithHexString:@"#554C41"];
	cell.detailTextLabel.font = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
	cell.detailTextLabel.numberOfLines = 1;
	cell.detailTextLabel.text = callNumber;
	
	if ([color isEqualToString:@"green"])
		cell.imageView.image = [UIImage imageNamed:@"dining/dining-status-open.png"];
	
	else if ([color isEqualToString:@"yellow"])
		cell.imageView.image = [UIImage imageNamed:@"dining/dining-status-open-w-restrictions.png"];
	
	else
		cell.imageView.image = [UIImage imageNamed:@"dining/dining-status-closed.png"];
	
	if (([canRequest isEqualToString:@"YES"]) || ([canScanAndDeliver isEqualToString:@"YES"]))
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	
    return cell;
	
}


-(UITableViewCell *) sectionTypeFIVE:(NSIndexPath *)indexPath tableView:(UITableView *)tableView{
	
	static NSString *CellIdentifier = @"CellTypeFOUR";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	cell.textLabel.text = @"Contact library/archive";	
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	
    return cell;
	
}

- (CGFloat)heightForRowAtIndexPathSectionONE:(NSIndexPath *)indexPath tableView:(UITableView *)tableView{
    
	return [LibrariesMultiLineCell heightForCellWithStyle:UITableViewCellStyleDefault
										   tableView:tableView 
												text:@"temporary text one liner"
										maxTextLines:1
										  detailText:nil
									  maxDetailLines:0
												font:nil 
										  detailFont:nil
									   accessoryType:UITableViewCellAccessoryDisclosureIndicator
										   cellImage:YES];
}

- (CGFloat)heightForRowAtIndexPathSectionTWO:(NSIndexPath *)indexPath tableView:(UITableView *)tableView{
	return [LibrariesMultiLineCell heightForCellWithStyle:UITableViewCellStyleSubtitle
												tableView:tableView 
													 text:@"temporary text one liner"
											 maxTextLines:1
											   detailText:@"temp place holder for cell nbr"
										   maxDetailLines:1
													 font:nil 
											   detailFont:nil
											accessoryType:UITableViewCellAccessoryDisclosureIndicator
												cellImage:YES];
}

- (CGFloat)heightForRowAtIndexPathSectionTHREE:(NSIndexPath *)indexPath tableView:(UITableView *)tableView{
	if ((limitedView == YES) && (indexPath.row >= 5)){
		return 35;
	}
	
	return [LibrariesMultiLineCell heightForCellWithStyle:UITableViewCellStyleSubtitle
												tableView:tableView 
													 text:@"temporary text one liner"
											 maxTextLines:1
											   detailText:@"concatenation temp text wth call nbr"
										   maxDetailLines:1
													 font:nil 
											   detailFont:nil
											accessoryType:UITableViewCellAccessoryDisclosureIndicator
												cellImage:YES];
}

- (CGFloat)heightForRowAtIndexPathSectionFOUR:(NSIndexPath *)indexPath tableView:(UITableView *)tableView{
	
	if ((limitedView == YES) && (indexPath.row >= 5)){
		return 35;
	}
	
	NSDictionary * collection = [availabilityCategories objectAtIndex:indexPath.section];
	NSArray * stats = (NSArray *)[collection objectForKey:@"itemsByStat"];
	
	NSMutableArray * items = [[NSMutableArray alloc] init];
	int indexCount =0;
	
	for(NSDictionary * statDict in stats) {
		NSArray * availableItems = (NSArray *)[statDict objectForKey:@"availableItems"];
		NSArray * checkedOutItems = (NSArray * )[statDict objectForKey:@"checkedOutItems"];
		NSArray * unavailableItems = (NSArray * )[statDict objectForKey:@"unavailableItems"];
		
		for(NSDictionary * item in availableItems) {
			[items insertObject:item atIndex:indexCount];
			indexCount++;
		}
		
		for(NSDictionary * item1 in checkedOutItems) {
			[items insertObject:item1 atIndex:indexCount];
			indexCount++;
		}
		
		for(NSDictionary * item2 in unavailableItems) {
			[items insertObject:item2 atIndex:indexCount];
			indexCount++;
		}
	}
	
	
	NSDictionary * itemForRow = [items objectAtIndex:indexPath.row];
	NSString * canRequest = [itemForRow objectForKey:@"canRequest"];
	NSString * canScanAndDeliver = [itemForRow objectForKey:@"canScanAndDeliver"];
	
	NSString * callNumber = [itemForRow objectForKey:@"callNumber"];
	NSString * desc = [itemForRow objectForKey:@"description"];
	NSString * statMain = [itemForRow objectForKey:@"statMain"];
	callNumber = [NSString stringWithFormat:@"%@-%@\n%@", desc, callNumber, statMain];
	
	NSString * cellText = @"temp place holder";
	NSString * detailText = callNumber;
	UITableViewCellAccessoryType accessoryType = UITableViewCellAccessoryDisclosureIndicator;

	
	if (([canRequest isEqualToString:@"NO"]) && ([canScanAndDeliver isEqualToString:@"NO"]))
		accessoryType = UITableViewCellAccessoryNone;

	return [LibrariesMultiLineCell heightForCellWithStyle:UITableViewCellStyleSubtitle
												tableView:tableView 
													 text:cellText
											 maxTextLines:1
											   detailText:detailText
										   maxDetailLines:4
													 font:nil 
											   detailFont:nil
											accessoryType:accessoryType
												cellImage:YES];
}


- (CGFloat)heightForRowAtIndexPathSectionFIVE:(NSIndexPath *)indexPath tableView:(UITableView *)tableView{
    
	return [LibrariesMultiLineCell heightForCellWithStyle:UITableViewCellStyleDefault
												tableView:tableView 
													 text:@"Contact library/archive"
											 maxTextLines:1
											   detailText:nil
										   maxDetailLines:0
													 font:nil 
											   detailFont:nil
											accessoryType:UITableViewCellAccessoryDisclosureIndicator
												cellImage:YES];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [availabilityCategories count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.

	NSDictionary * collection = [availabilityCategories objectAtIndex:section];	
	NSArray * stats = (NSArray *)[collection objectForKey:@"itemsByStat"];
	NSString * displayType = [collection objectForKey:@"displayType"];
	
	int availRowCount = 0;
	int checkedOutRowCount = 0;
	int unavailRowCount = 0;
	
	int availCount = 0;
	int checkedOutCount = 0;
	int unavailCount = 0;
	
	int itemStats = 0;
	
	if ([displayType isEqualToString:@"V"]) {
		return 1;
	}
	
	for(NSDictionary * statDict in stats){
		
		NSArray * availableItemsTemp = (NSArray *)[statDict objectForKey:@"availableItems"];
		NSArray * checkedOutItemsTemp = (NSArray * )[statDict objectForKey:@"checkedOutItems"];
		NSArray * unavailableItemsTemp = (NSArray * )[statDict objectForKey:@"unavailableItems"];
		
		if ([availableItemsTemp count] > 0) {
			availRowCount++;
			availCount += [availableItemsTemp count];
		}
		
		if ([checkedOutItemsTemp count] > 0){
			checkedOutRowCount++;
			checkedOutCount += [checkedOutItemsTemp count];
		}
		
		if ([unavailableItemsTemp count] > 0){
			unavailRowCount = 1;
			unavailCount += [unavailableItemsTemp count];
		}
	}
	
	
	if (availCount > 0)
		itemStats++;
	
	if (checkedOutCount > 0)
		itemStats++;
	
	if (unavailCount > 0)
		itemStats++;
	
	if ([displayType isEqualToString:@"I"]){
		return itemStats;		
	}
	
	else if ([displayType isEqualToString:@"II"])
		return availRowCount + checkedOutRowCount + unavailRowCount;
	
	else if ([displayType isEqualToString:@"III"]){
		int rows = availCount + checkedOutCount + unavailCount;
		
		if ((limitedView == YES) && (rows >= 5))
			return 6;
		else {
			return rows;
		}

	}
	
	else if ([displayType isEqualToString:@"IV"]) {
		int rows = availCount + checkedOutCount + unavailCount;
		
		if ((limitedView == YES) && (rows >= 5))
			return 6;
		else {
			return rows;
		};
	}


    return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSDictionary * collection = [availabilityCategories objectAtIndex:indexPath.section];	
	NSString * displayType = [collection objectForKey:@"displayType"];

	if ([displayType isEqualToString:@"I"])
		return [self sectionTypeONE:indexPath tableView:tableView];

	else if ([displayType isEqualToString:@"II"])
		return [self sectionTypeTWO:indexPath tableView:tableView];
	
	else if ([displayType isEqualToString:@"III"])
		return [self sectionTypeTHREE:indexPath tableView:tableView];
	
	else if ([displayType isEqualToString:@"IV"])
		return [self sectionTypeFOUR:indexPath tableView:tableView];
	
	else if ([displayType isEqualToString:@"V"])
		return [self sectionTypeFIVE:indexPath tableView:tableView];

	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	
	NSDictionary * collection = [availabilityCategories objectAtIndex:indexPath.section];	
	NSString * displayType = [collection objectForKey:@"displayType"];
	
	if ([displayType isEqualToString:@"I"])
		return [self heightForRowAtIndexPathSectionONE:indexPath tableView:tableView];
	
	else if ([displayType isEqualToString:@"II"])
		return [self heightForRowAtIndexPathSectionTWO:indexPath tableView:tableView];
	
	else if ([displayType isEqualToString:@"III"])
		return [self heightForRowAtIndexPathSectionTHREE:indexPath tableView:tableView];
	
	else if ([displayType isEqualToString:@"IV"])
		return [self heightForRowAtIndexPathSectionFOUR:indexPath tableView:tableView];
	
	else if ([displayType isEqualToString:@"V"])
		return [self heightForRowAtIndexPathSectionFIVE:indexPath tableView:tableView];
	return 0;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
	NSDictionary * collection = [availabilityCategories objectAtIndex:indexPath.section];	
	NSString * displayType = [collection objectForKey:@"displayType"];
	NSArray * stats = (NSArray *)[collection objectForKey:@"itemsByStat"];
	
	if ([displayType isEqualToString:@"I"]){
		
		NSDictionary * statDict = (NSDictionary *)[stats lastObject];
		int availCount = 0;
		availCount = [[statDict objectForKey:@"availCount"] intValue];
		
		int unavailCount = 0;
		unavailCount = [[statDict objectForKey:@"unavailCount"] intValue];
		
		int checkedOutCount = 0;
		checkedOutCount = [[statDict objectForKey:@"checkedOutCount"] intValue];
		
		NSArray * availableItems = (NSArray *)[statDict objectForKey:@"availableItems"];
		NSArray * checkedOutItems = (NSArray * )[statDict objectForKey:@"checkedOutItems"];
		NSArray * unavailableItems = (NSArray * )[statDict objectForKey:@"unavailableItems"];
		
		NSArray * items = [[NSArray alloc] init];
		if (indexPath.row == 0) {// available
			
			if (availCount > 0) {
				items = availableItems;
			}
			else if (checkedOutCount > 0){
				items = checkedOutItems;
			}
			
			else if (unavailCount > 0){
				items = unavailableItems;
			}			
		}
		
		else if (indexPath.row == 1) {// checked out
			if (checkedOutCount > 0){
				items = checkedOutItems;
			}
			
			else if (unavailCount > 0){
				items = unavailableItems;
			}	
		}
		
		else if (indexPath.row == 2) {// unavailable
			if (unavailCount > 0){
				items = unavailableItems;
			}	
		}
		
		NSString * reqUrl = @"";
		NSString * scanUrl = @"";
		
		for(NSDictionary * availD in items){
			if ([[availD objectForKey:@"requestUrl"] length] > 0){
				reqUrl = [availD objectForKey:@"requestUrl"];
			}
			if ([[availD objectForKey:@"scanAndDeliverUrl"] length] > 0){
				scanUrl = [availD objectForKey:@"scanAndDeliverUrl"];
			}
		}
		if (([reqUrl length] == 0) && ([scanUrl length] == 0))
			return;
			
		else if (([reqUrl length] > 0) && ([scanUrl length] == 0)){
			MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
			
			RequestWebViewModalViewController *modalVC = [[RequestWebViewModalViewController alloc] initWithRequestUrl:reqUrl title:@"Request Item"];
			
			//[self.navigationController pushViewController:modalVC animated:YES];
			//[modalVC release];
			
			[appDelegate presentAppModalViewController:modalVC animated:YES];
			[modalVC release];
		}
		else if (([scanUrl length] > 0) && ([reqUrl length] == 0)){
			MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
			
			RequestWebViewModalViewController *modalVC = [[RequestWebViewModalViewController alloc] initWithRequestUrl:scanUrl title:@"Scan & Deliver Item"];
			
			//[self.navigationController pushViewController:modalVC animated:YES];
			//[modalVC release];
			
			[appDelegate presentAppModalViewController:modalVC animated:YES];
			[modalVC release];
		}
		else {
			[self showActionSheet:items];
		}
	}
	
	else if ([displayType isEqualToString:@"II"]){
		
		
		int availRowCount = 0;
		int checkedOutRowCount = 0;
		int unavailRowCount = 0;
				
		int availRowMax = -1;
		int checkedOutRowMax = -1;
		int unavailRowMax = -1;

		
		NSMutableArray * availItems = [[NSMutableArray alloc] init];
		NSMutableArray * checkedOutItems = [[NSMutableArray alloc] init];
		NSMutableArray * unavailItems = [[NSMutableArray alloc] init];
		
		for(NSDictionary * statDict in stats){
			
			NSArray * availableItemsTemp = (NSArray *)[statDict objectForKey:@"availableItems"];
			NSArray * checkedOutItemsTemp = (NSArray * )[statDict objectForKey:@"checkedOutItems"];
			NSArray * unavailableItemsTemp = (NSArray * )[statDict objectForKey:@"unavailableItems"];
			
			if ([availableItemsTemp count] > 0) {
				[availItems insertObject:availableItemsTemp atIndex:availRowCount];
				availRowCount++;
			}
			
			if ([checkedOutItemsTemp count] > 0){
				[checkedOutItems insertObject:checkedOutItemsTemp atIndex:checkedOutRowCount];
				checkedOutRowCount++;
			}
			
			for(NSDictionary * unavailDict in unavailableItemsTemp){
				[unavailItems insertObject:unavailDict atIndex:unavailRowCount];
				unavailRowCount++;
			}
			
		}
		
		availRowMax = availRowCount - 1;
		checkedOutRowMax = availRowMax + checkedOutRowCount;
		unavailRowMax = checkedOutRowMax++;

		NSArray * itemsForStatus = [[NSArray alloc] init];
		if (indexPath.row <= availRowMax){
			itemsForStatus = [availItems objectAtIndex:indexPath.row];
		}
		
		else if (indexPath.row <= checkedOutRowMax){
			itemsForStatus = [checkedOutItems objectAtIndex:indexPath.row - checkedOutRowCount];
		}
		
		else if (indexPath.row == unavailRowMax){
			itemsForStatus = [unavailItems retain];
		}
		
		NSString * reqUrl = @"";
		NSString * scanUrl = @"";
		
		for(NSDictionary * availD in itemsForStatus){
			if ([[availD objectForKey:@"requestUrl"] length] > 0){
				reqUrl = [availD objectForKey:@"requestUrl"];
			}
			if ([[availD objectForKey:@"scanAndDeliverUrl"] length] > 0){
				scanUrl = [availD objectForKey:@"scanAndDeliverUrl"];
			}
		}
		if (([reqUrl length] == 0) && ([scanUrl length] == 0)){
			return;
		}
		
		else if (([reqUrl length] > 0) && ([scanUrl length] == 0)){
			MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
			
			RequestWebViewModalViewController *modalVC = [[RequestWebViewModalViewController alloc] initWithRequestUrl:reqUrl title:@"Request Item"];
			
			//[self.navigationController pushViewController:modalVC animated:YES];
			//[modalVC release];
			
			[appDelegate presentAppModalViewController:modalVC animated:YES];
			[modalVC release];
		}
		else if (([scanUrl length] > 0) && ([reqUrl length] == 0)){
			MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
			
			RequestWebViewModalViewController *modalVC = [[RequestWebViewModalViewController alloc] initWithRequestUrl:scanUrl title:@"Scan & Deliver Item"];
			
			//[self.navigationController pushViewController:modalVC animated:YES];
			//[modalVC release];
			
			[appDelegate presentAppModalViewController:modalVC animated:YES];
			[modalVC release];
		}
		else {
			[self showActionSheet:itemsForStatus];
		}
		
		
	}
	
	else if (([displayType isEqualToString:@"III"]) || ([displayType isEqualToString:@"IV"])){
		
		if ((limitedView == YES) && (indexPath.row >= 5)){
			limitedView = NO;
			[self.tableView reloadData];
			return;
		}
		
		NSMutableArray * items = [[NSMutableArray alloc] init];
		int indexCount =0;
		
		for(NSDictionary * statDict in stats) {
			NSArray * availableItems = (NSArray *)[statDict objectForKey:@"availableItems"];
			NSArray * checkedOutItems = (NSArray * )[statDict objectForKey:@"checkedOutItems"];
			NSArray * unavailableItems = (NSArray * )[statDict objectForKey:@"unavailableItems"];
			
			for(NSDictionary * item in availableItems) {
				[items insertObject:item atIndex:indexCount];
				indexCount++;
			}
			
			for(NSDictionary * item1 in checkedOutItems) {
				[items insertObject:item1 atIndex:indexCount];
				indexCount++;
			}
			
			for(NSDictionary * item2 in unavailableItems) {
				[items insertObject:item2 atIndex:indexCount];
				indexCount++;
			}
		}
		
		
		NSDictionary * itemForRow = [items objectAtIndex:indexPath.row];
		NSString * canRequest = [itemForRow objectForKey:@"canRequest"];
		NSString * canScanAndDeliver = [itemForRow objectForKey:@"canScanAndDeliver"];
		
		if (([canRequest isEqualToString:@"YES"]) && ([canScanAndDeliver isEqualToString:@"YES"]))
			[self showActionSheet:[[NSArray alloc] initWithObjects:itemForRow, nil]];
		
		else if ([canRequest isEqualToString:@"YES"]) {
			
			NSString * reqUrl = [itemForRow objectForKey:@"requestUrl"];
			MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
			
			RequestWebViewModalViewController *modalVC = [[RequestWebViewModalViewController alloc] initWithRequestUrl:reqUrl title:@"Request Item"];
			
			//[self.navigationController pushViewController:modalVC animated:YES];
			//[modalVC release];
			
			[appDelegate presentAppModalViewController:modalVC animated:YES];
			[modalVC release];
		}
		
		else if ([canScanAndDeliver isEqualToString:@"YES"]) {
			
			NSString * scanAndDeliverUrl = [itemForRow objectForKey:@"scanAndDeliverUrl"];
			MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
			
			RequestWebViewModalViewController *modalVC = [[RequestWebViewModalViewController alloc] initWithRequestUrl:scanAndDeliverUrl title:@"Scan & Deliver Item"];
			
			//[self.navigationController pushViewController:modalVC animated:YES];
			//[modalVC release];
			
			[appDelegate presentAppModalViewController:modalVC animated:YES];
			[modalVC release];
		}
		
	}
	
	return;	
	
}

- (UIView *)tableView: (UITableView *)tableView viewForHeaderInSection: (NSInteger)section{
	
	UIView * view;
	view = nil;

	
	NSDictionary * collection = [availabilityCategories objectAtIndex:section];	
	NSArray * stats = (NSArray *)[collection objectForKey:@"itemsByStat"];
	NSString * displayType = [collection objectForKey:@"displayType"];
	//NSString *collectionTitle = [collection objectForKey:@"collectionName"];
	NSString *collectionCallNbr = [collection objectForKey:@"collectionCallNumber"];
	
	
	if ([displayType isEqualToString:@"V"]) {
		
		UILabel * headerCollectionName;
		UILabel * headerCollectionCallNumber;
		UILabel * headerCollectionAvailVal;
		
		NSDictionary * statDict = (NSDictionary *)[stats lastObject];
		NSDictionary * collectionItem = (NSDictionary *)[((NSArray *)[statDict objectForKey:@"collectionOnlyItems"]) lastObject];
		
		NSString * collectionName = [collectionItem objectForKey:@"collectionName"];
		NSString * callNbr = [collectionItem objectForKey:@"collectionCallNumber"];
		NSString * availVal = [(NSArray*)[collectionItem objectForKey:@"collectionAvailVal"] lastObject];
		
		CGFloat heightName = [collectionName
							  sizeWithFont:[UIFont boldSystemFontOfSize:17]
							  constrainedToSize:CGSizeMake(280, 2000)         
							  lineBreakMode:UILineBreakModeWordWrap].height;
		
		CGFloat heightCallNbr = [callNbr
								 sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
								 constrainedToSize:CGSizeMake(280, 2000)         
								 lineBreakMode:UILineBreakModeWordWrap].height;
		
		CGFloat heightAvailVal = [availVal
								  sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
								  constrainedToSize:CGSizeMake(280, 2000)         
								  lineBreakMode:UILineBreakModeWordWrap].height;
		
		headerCollectionName = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 0.0, 280, heightName)];
		headerCollectionName.text = collectionName;
		headerCollectionName.font = [UIFont boldSystemFontOfSize:17];
		headerCollectionName.textColor = [UIColor colorWithHexString:@"#554C41"];
		headerCollectionName.backgroundColor = [UIColor clearColor];	
		headerCollectionName.lineBreakMode = UILineBreakModeTailTruncation;
		headerCollectionName.numberOfLines = 5;
		
		headerCollectionCallNumber = [[UILabel alloc] initWithFrame:CGRectMake(12.0, heightName, 280, heightCallNbr)];
		headerCollectionCallNumber.text = callNbr;
		headerCollectionCallNumber.font =  [UIFont fontWithName:STANDARD_FONT size:13];
		headerCollectionCallNumber.textColor = [UIColor colorWithHexString:@"#554C41"];
		headerCollectionCallNumber.backgroundColor = [UIColor clearColor];	
		headerCollectionCallNumber.lineBreakMode = UILineBreakModeTailTruncation;
		headerCollectionCallNumber.numberOfLines = 5;
		
		headerCollectionAvailVal = [[UILabel alloc] initWithFrame:CGRectMake(12.0, heightName + heightCallNbr, 280, heightAvailVal)];
		headerCollectionAvailVal.text = availVal;
		headerCollectionAvailVal.font =  [UIFont fontWithName:STANDARD_FONT size:13];
		headerCollectionAvailVal.textColor = [UIColor colorWithHexString:@"#554C41"];
		headerCollectionAvailVal.backgroundColor = [UIColor clearColor];	
		headerCollectionAvailVal.lineBreakMode = UILineBreakModeTailTruncation;
		headerCollectionAvailVal.numberOfLines = 5;
		
		CGFloat height = heightName + heightCallNbr + heightAvailVal;
		
		view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, height)];
		[view addSubview:headerCollectionName];
		[view addSubview:headerCollectionCallNumber];
		[view addSubview:headerCollectionAvailVal];
		
		return view;
	}

	else {
		NSString * text0 = @"";
		NSString * text1 = @"";
		NSString * text2 = @"";
		
		UILabel * headerLabel0;
		UILabel * headerLabel1;
		UILabel * headerLabel2;
		
		NSDictionary * statDict = (NSDictionary *)[stats lastObject];
		
		text0 = [collection objectForKey:@"collectionName"];
		
		
		if (([displayType isEqualToString:@"I"]) || ([displayType isEqualToString:@"III"]))
			text1 = [statDict objectForKey:@"statMain"];
		
		if ([text1 length] > 0)
			text1 = [text1 stringByReplacingCharactersInRange:
					 NSMakeRange(0,1) withString:[[text1 substringToIndex:1] capitalizedString]];
		
		text2 = collectionCallNbr;
		
		CGFloat height0 = [text0
						   sizeWithFont:[UIFont boldSystemFontOfSize:17]
						   constrainedToSize:CGSizeMake(280.0, 2000)         
						   lineBreakMode:UILineBreakModeWordWrap].height;
		
		CGFloat height1 = [text1
						  sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
						  constrainedToSize:CGSizeMake(280.0, 2000)         
						  lineBreakMode:UILineBreakModeWordWrap].height;
		
		CGFloat height2 = [text2
						   sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
						   constrainedToSize:CGSizeMake(280.0, 2000)         
						   lineBreakMode:UILineBreakModeWordWrap].height;

		headerLabel0 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 0.0, 280.0, height0)];
		headerLabel0.text = text0;
		headerLabel0.font = [UIFont boldSystemFontOfSize:17];
		headerLabel0.textColor = [UIColor colorWithHexString:@"#554C41"];
		headerLabel0.backgroundColor = [UIColor clearColor];	
		headerLabel0.lineBreakMode = UILineBreakModeTailTruncation;
		headerLabel0.numberOfLines = 5;
		
		
		headerLabel1 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, height0, 280.0, height1)];
		headerLabel1.text = text1;
		headerLabel1.font = [UIFont fontWithName:STANDARD_FONT size:13];
		headerLabel1.textColor = [UIColor colorWithHexString:@"#554C41"];
		headerLabel1.backgroundColor = [UIColor clearColor];	
		headerLabel1.lineBreakMode = UILineBreakModeTailTruncation;
		headerLabel1.numberOfLines = 5;
		
		
		headerLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, height0 + height1, 280.0, height2)];
		headerLabel2.text = text2;
		headerLabel2.font = [UIFont fontWithName:STANDARD_FONT size:13];
		headerLabel2.textColor = [UIColor colorWithHexString:@"#554C41"];
		headerLabel2.backgroundColor = [UIColor clearColor];	
		headerLabel2.lineBreakMode = UILineBreakModeTailTruncation;
		headerLabel2.numberOfLines = 5;
		
		view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, height0 + height1 + height2)];
		[view addSubview:headerLabel0];
		[view addSubview:headerLabel1];
		[view addSubview:headerLabel2];
		
		
		return view;
	}

	

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	
	NSDictionary * collection = [availabilityCategories objectAtIndex:section];	
	NSArray * stats = (NSArray *)[collection objectForKey:@"itemsByStat"];
	NSString * displayType = [collection objectForKey:@"displayType"];
	//NSString *collectionTitle = [collection objectForKey:@"collectionName"];
	NSString *collectionCallNbr = [collection objectForKey:@"collectionCallNumber"];
	
	
	if ([displayType isEqualToString:@"V"]) {
		NSDictionary * statDict = (NSDictionary *)[stats lastObject];
		NSDictionary * collectionItem = (NSDictionary *)[((NSArray *)[statDict objectForKey:@"collectionOnlyItems"]) lastObject];
		
		NSString * collectionName = [collectionItem objectForKey:@"collectionName"];
		NSString * callNbr = [collectionItem objectForKey:@"collectionCallNumber"];
		NSString * availVal = [(NSArray*)[collectionItem objectForKey:@"collectionAvailVal"] lastObject];
		
		CGFloat heightName = [collectionName
							  sizeWithFont:[UIFont boldSystemFontOfSize:17]
							  constrainedToSize:CGSizeMake(280, 2000)         
							  lineBreakMode:UILineBreakModeWordWrap].height;
		
		CGFloat heightCallNbr = [callNbr
								 sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
								 constrainedToSize:CGSizeMake(280, 2000)         
								 lineBreakMode:UILineBreakModeWordWrap].height;
		
		CGFloat heightAvailVal = [availVal
								  sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
								  constrainedToSize:CGSizeMake(280, 2000)         
								  lineBreakMode:UILineBreakModeWordWrap].height;
		
		CGFloat height = heightName + heightCallNbr + heightAvailVal;

		
		return height + 4;
	}
	
	else {
		NSString * text0 = @"";
		NSString * text1 = @"";
		NSString * text2 = @"";
		
		NSDictionary * statDict = (NSDictionary *)[stats lastObject];
		
		text0 = [statDict objectForKey:@"collectionName"];
		
		
		if (([displayType isEqualToString:@"I"]) || ([displayType isEqualToString:@"III"]))
			text1 = [statDict objectForKey:@"statMain"];
		
		if ([text1 length] > 0)
			text1 = [text1 stringByReplacingCharactersInRange:
					 NSMakeRange(0,1) withString:[[text1 substringToIndex:1] capitalizedString]];
		
		text2 = collectionCallNbr;
		
		CGFloat height0 = [text0
						   sizeWithFont:[UIFont systemFontOfSize:17]
						   constrainedToSize:CGSizeMake(280.0, 2000)         
						   lineBreakMode:UILineBreakModeWordWrap].height;
		
		CGFloat height1 = [text1
						   sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
						   constrainedToSize:CGSizeMake(280.0, 2000)         
						   lineBreakMode:UILineBreakModeWordWrap].height;
		
		CGFloat height2 = [text2
						   sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
						   constrainedToSize:CGSizeMake(280.0, 2000)         
						   lineBreakMode:UILineBreakModeWordWrap].height;
		
		return height0 + height1 + height2 + 4;

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
}


- (void)dealloc {
	self.parentViewApiRequest.jsonDelegate = nil;
    [super dealloc];
	
}

#pragma mark -
#pragma mark JSONAPIRequest Delegate function 

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result {
	
	NSDictionary *libraryDictionary = (NSDictionary *)result;
	
	NSString * hrsToday = [libraryDictionary objectForKey:@"hrsOpenToday"];
	
	if ([hrsToday isEqualToString:@"closed"])
		openToday = @"Closed Today";
	
	else {
		openToday = [NSString stringWithFormat: @"Open today from %@", hrsToday];
	}
	
	[self setupLayout];

}

- (BOOL)request:(JSONAPIRequest *)request shouldDisplayAlertForError:(NSError *)error {
	
    return YES;
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error {

	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Failed", nil)
														message:NSLocalizedString(@"Could not retrieve information about today's open hours", nil)
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

#pragma mark UIActionSheet setup

-(void) showActionSheet:(NSArray *)items{
	
	actionSheetItems = [[NSArray alloc] init];
	actionSheetItems = [items retain];
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Item Action Options" 
															 delegate:self 
													cancelButtonTitle:@"Cancel" 
											   destructiveButtonTitle:nil 
													otherButtonTitles:@"Request Item", @"Scan & Deliver", nil];

	actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;

    [actionSheet showInView:self.view];
    [actionSheet release];
	
	return;
}

#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
	
	if (buttonIndex == 2) {
        NSLog(@"Cancel");
		return;
    }
	
	
	NSString * reqUrl = @"";
	if (buttonIndex == 0) {
		 NSLog(@"Request Item");
		
		for(NSDictionary * availD in actionSheetItems){
			if ([[availD objectForKey:@"canRequest"] isEqualToString:@"YES"])
				if ([[availD objectForKey:@"requestUrl"] length] > 0)
					reqUrl = [availD objectForKey:@"requestUrl"];
		}
       
    } else if (buttonIndex == 1) {
        NSLog(@"Scan & Deliver");
		
		for(NSDictionary * availD in actionSheetItems){
			if ([[availD objectForKey:@"canScanAndDeliver"] isEqualToString:@"YES"])
				if ([[availD objectForKey:@"scanAndDeliverUrl"] length] > 0)
					reqUrl = [availD objectForKey:@"scanAndDeliverUrl"];
		}
    }
	
	if ([reqUrl length] > 0) {
		NSLog(@"%@", reqUrl);
		
		MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
		
		NSString * titleStr = @"";
		
		if (buttonIndex == 0)
			titleStr = @"Request Item";
		
		else if (buttonIndex == 1)
			titleStr = @"Scan & Deliver Item";
		
		RequestWebViewModalViewController *modalVC = [[RequestWebViewModalViewController alloc] initWithRequestUrl:reqUrl title:titleStr];
		
		//[self.navigationController pushViewController:modalVC animated:YES];
		//[modalVC release];
		
		[appDelegate presentAppModalViewController:modalVC animated:YES];
		[modalVC release];
	}
	
	return;
	
}


@end

