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
	
	if (![libraryName isEqualToString:primaryName])
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
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 0.0, 250, height1)];

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

	
	UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, height1 + 5.0, 250, height2)];
	label2.text = openTodayString;
	label2.font = [UIFont fontWithName:COURSE_NUMBER_FONT
								  size:13];
	label2.textColor = [UIColor colorWithHexString:@"#666666"];
	label2.backgroundColor = [UIColor clearColor];	
	label2.lineBreakMode = UILineBreakModeWordWrap;
	label2.numberOfLines = 1;
	
	
	infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
	infoButton.frame = CGRectMake(self.tableView.frame.size.width - 60.0 , 5, 50.0, 50.0);
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
									  initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, headerView.frame.size.height + 10)];
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
															message:@"Could not connect to the server" 
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
				
				NSArray * itemsByStat = (NSArray *)[tempDict objectForKey:@"itemsByStat"];

					
					
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
						availabilityCategories = itemsByStat;
						[self viewWillAppear:YES];		
					}
					else {
						UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
																			message:@"Could not retrieve item-availability" 
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



-(UITableViewCell *) sectionTypeZero:(NSIndexPath *)indexPath tableView:(UITableView *)tableView{
	
	static NSString *CellIdentifier = @"CellType0";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	NSDictionary * statDict = [availabilityCategories objectAtIndex:indexPath.section];
	
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
	
	
	/*UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(230.0, cell.frame.size.height/2 - 10, 50.0, 20.0)];
	label2.text = @"Request";
	label2.font = [UIFont fontWithName:COURSE_NUMBER_FONT
								  size:13];
	label2.textColor = [UIColor colorWithHexString:@"#666666"];
	label2.backgroundColor = [UIColor clearColor];	
	label2.lineBreakMode = UILineBreakModeWordWrap;
	label2.numberOfLines = 1;
	 */
	
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


-(UITableViewCell *) sectionTypeOne:(NSIndexPath *)indexPath tableView:(UITableView *)tableView{
	
	static NSString *CellIdentifier = @"CellType1";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
	NSDictionary * statDict = [availabilityCategories objectAtIndex:indexPath.section];
	
	NSMutableArray * items = [[NSMutableArray alloc] init];
	int indexCount =0;
	
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
	
	cell.textLabel.text = status;
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


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [availabilityCategories count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	
	int row = 0;
	NSDictionary * statDict = [availabilityCategories objectAtIndex:section];
	
	
	int availCount = 0;
	availCount = [[statDict objectForKey:@"availCount"] intValue];
	
	int unavailCount = 0;
	unavailCount = [[statDict objectForKey:@"unavailCount"] intValue];
	
	int checkedOutCount = 0;
	checkedOutCount = [[statDict objectForKey:@"checkedOutCount"] intValue];
	
	int requestCount = 0;
	requestCount = [[statDict objectForKey:@"requestCount"] intValue];
	
	if (availCount > 0)
		row++;
	
	if (checkedOutCount > 0)
		row++;
	
	if (unavailCount > 0)
		row++;
	
	if ([[sectionType objectForKey:[NSString stringWithFormat:@"%d",section]] isEqualToString:sectionType0])
		return row;
	
	else if ([[sectionType objectForKey:[NSString stringWithFormat:@"%d", section]] isEqualToString:sectionType1])
		return availCount + unavailCount + checkedOutCount;

	
    return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	if ([[sectionType objectForKey:[NSString stringWithFormat:@"%d", indexPath.section]] isEqualToString:sectionType0])
		return [self sectionTypeZero:indexPath tableView:tableView];
	
	else if ([[sectionType objectForKey:[NSString stringWithFormat:@"%d", indexPath.section]] isEqualToString:sectionType1])
		return [self sectionTypeOne:indexPath tableView:tableView];
	
	return nil;
}




#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	

	
	if ([[sectionType objectForKey:[NSString stringWithFormat:@"%d", indexPath.section]] isEqualToString:sectionType0]){
		
		
		NSDictionary * statDict = [availabilityCategories objectAtIndex:indexPath.section];
		
		int availCount = 0;
		availCount = [[statDict objectForKey:@"availCount"] intValue];
		
		int unavailCount = 0;
		unavailCount = [[statDict objectForKey:@"unavailCount"] intValue];
		
		int checkedOutCount = 0;
		checkedOutCount = [[statDict objectForKey:@"checkedOutCount"] intValue];
		
		int requestCount = 0;
		requestCount = [[statDict objectForKey:@"requestCount"] intValue];
		
		int scanAndDeliverCount = 0;
		scanAndDeliverCount = [[statDict objectForKey:@"scanAndDeliverCount"] intValue];
		
		if ((requestCount > 0) || (scanAndDeliverCount > 0)){
			
			//just present the reqUrl
			NSArray * availableItems = (NSArray *)[statDict objectForKey:@"availableItems"];
			NSArray * checkedOutItems = (NSArray * )[statDict objectForKey:@"checkedOutItems"];
			
			NSString * reqUrl = @"";
			NSString * scanUrl = @"";
			if (indexPath.row == 0){
				if (availCount > 0){

					for(NSDictionary * availD in availableItems){
						if ([[availD objectForKey:@"requestUrl"] length] > 0){
							reqUrl = [availD objectForKey:@"requestUrl"];
						}
						if ([[availD objectForKey:@"scanAndDeliverUrl"] length] > 0){
							scanUrl = [availD objectForKey:@"scanAndDeliverUrl"];
						}
					}
				}
				else if (checkedOutCount > 0) {
					for(NSDictionary * availD in checkedOutItems){
						if ([[availD objectForKey:@"requestUrl"] length] > 0)
							reqUrl = [availD objectForKey:@"requestUrl"];
						
						if ([[availD objectForKey:@"scanAndDeliverUrl"] length] > 0){
							scanUrl = [availD objectForKey:@"scanAndDeliverUrl"];
						}
					}
				}
			}
			
			else if (indexPath.row == 1){
				
				if (checkedOutCount > 0){
					for(NSDictionary * availD in checkedOutItems){
						if ([[availD objectForKey:@"requestUrl"] length] > 0)
							reqUrl = [availD objectForKey:@"requestUrl"];
						
						if ([[availD objectForKey:@"scanAndDeliverUrl"] length] > 0){
							scanUrl = [availD objectForKey:@"scanAndDeliverUrl"];
						}
					}
				}				
			}
			else {
				return;
			}
			
			
			if (([reqUrl length] > 0) && ([scanUrl length] == 0)){
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
				[self showActionSheet:indexPath.section];
			}

			

		}
		
		else if ((requestCount == 0) && (scanAndDeliverCount == 0))
			return; // no action
		
		else
			[self showActionSheet:indexPath.section];

	}
	
	else if ([[sectionType objectForKey:[NSString stringWithFormat:@"%d", indexPath.section]] isEqualToString:sectionType1]) {
		
		NSDictionary * statDict = [availabilityCategories objectAtIndex:indexPath.section];
		
		NSMutableArray * items = [[NSMutableArray alloc] init];
		int indexCount =0;
		
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
		
		
		NSDictionary * itemForRow = [items objectAtIndex:indexPath.row];
		NSString * canRequest = [itemForRow objectForKey:@"canRequest"];
		NSString * canScanAndDeliver = [itemForRow objectForKey:@"canScanAndDeliver"];
		
		
		if ([canRequest isEqualToString:@"YES"]) {
			
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
	
	
}

- (UIView *)tableView: (UITableView *)tableView viewForHeaderInSection: (NSInteger)section{
	
	UIView * view;
	view = nil;
	NSString * text1 = @"";
	NSString * text2 = @"";
	
	NSDictionary * statDict = [availabilityCategories objectAtIndex:section];
	
	int collectionOnlyCount = 0;
	collectionOnlyCount = [[statDict objectForKey:@"collectionOnlyCount"] intValue];
	
	if (collectionOnlyCount > 0) {
		
		UILabel * headerCollectionName;
		UILabel * headerCollectionCallNumber;
		UILabel * headerCollectionAvailVal;
		
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
		
		headerCollectionCallNumber = [[UILabel alloc] initWithFrame:CGRectMake(12.0, heightName + 3, 280, heightCallNbr)];
		headerCollectionCallNumber.text = callNbr;
		headerCollectionCallNumber.font =  [UIFont fontWithName:STANDARD_FONT size:13];
		headerCollectionCallNumber.textColor = [UIColor colorWithHexString:@"#554C41"];
		headerCollectionCallNumber.backgroundColor = [UIColor clearColor];	
		headerCollectionCallNumber.lineBreakMode = UILineBreakModeTailTruncation;
		headerCollectionCallNumber.numberOfLines = 5;
		
		headerCollectionAvailVal = [[UILabel alloc] initWithFrame:CGRectMake(12.0, heightName + 3 + heightCallNbr + 3, 280, heightAvailVal)];
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
	
	UILabel * headerLabel1;
	UILabel * headerLabel2;
		
	text1 = [statDict objectForKey:@"statMain"];
	text1 = [text1 stringByReplacingCharactersInRange:
							 NSMakeRange(0,1) withString:[[text1 substringToIndex:1] capitalizedString]];
	text2 = [statDict objectForKey:@"callNumber"];
	
	CGFloat height = [text1
						  sizeWithFont:[UIFont boldSystemFontOfSize:17]
						  constrainedToSize:CGSizeMake(280.0, 2000)         
						  lineBreakMode:UILineBreakModeWordWrap].height;
	
	CGFloat height2 = [text2
					  sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
					  constrainedToSize:CGSizeMake(280.0, 2000)         
					  lineBreakMode:UILineBreakModeWordWrap].height;
	
	if (height > 21)
		height = 21;
		
		headerLabel1 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 0.0, 280.0, height)];
		headerLabel1.text = text1;
		headerLabel1.font = [UIFont boldSystemFontOfSize:17];
		headerLabel1.textColor = [UIColor colorWithHexString:@"#554C41"];
		headerLabel1.backgroundColor = [UIColor clearColor];	
		headerLabel1.lineBreakMode = UILineBreakModeTailTruncation;
		headerLabel1.numberOfLines = 5;

	
	headerLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, height + 3, 280.0, height2)];
	headerLabel2.text = text2;
	headerLabel2.font = [UIFont fontWithName:STANDARD_FONT size:13];
	headerLabel2.textColor = [UIColor colorWithHexString:@"#554C41"];
	headerLabel2.backgroundColor = [UIColor clearColor];	
	headerLabel2.lineBreakMode = UILineBreakModeTailTruncation;
	headerLabel2.numberOfLines = 5;
		
	view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, height + height2 +3.0)];
	[view addSubview:headerLabel1];
	[view addSubview:headerLabel2];

	
	return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {

	NSString * text1 = @"";
	NSString * text2 = @"";
	
	NSDictionary * statDict = [availabilityCategories objectAtIndex:section];
	
	int collectionOnlyCount = 0;
	collectionOnlyCount = [[statDict objectForKey:@"collectionOnlyCount"] intValue];
	
	if (collectionOnlyCount > 0) {
		
		UILabel * headerCollectionName;
		UILabel * headerCollectionCallNumber;
		UILabel * headerCollectionAvailVal;
		
		NSDictionary * collectionItem = (NSDictionary *)[((NSArray *)[statDict objectForKey:@"collectionOnlyItems"]) lastObject];
		
		NSString * collectionName = [collectionItem objectForKey:@"collectionName"];
		NSString * callNbr = [collectionItem objectForKey:@"collectionCallNumber"];
		NSString * availVal = [(NSArray*)[collectionItem objectForKey:@"collectionAvailVal"] lastObject];
		
		CGFloat heightName = [collectionName
							  sizeWithFont:[UIFont boldSystemFontOfSize:17]
							  constrainedToSize:CGSizeMake(250, 2000)         
							  lineBreakMode:UILineBreakModeWordWrap].height;
		
		CGFloat heightCallNbr = [callNbr
								 sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
								 constrainedToSize:CGSizeMake(200, 2000)         
								 lineBreakMode:UILineBreakModeWordWrap].height;
		
		CGFloat heightAvailVal = [availVal
								  sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
								  constrainedToSize:CGSizeMake(200, 2000)         
								  lineBreakMode:UILineBreakModeWordWrap].height;
		
		headerCollectionName = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 0.0, 250.0, heightName)];
		headerCollectionName.text = collectionName;
		headerCollectionName.font = [UIFont boldSystemFontOfSize:17];
		headerCollectionName.textColor = [UIColor colorWithHexString:@"#554C41"];
		headerCollectionName.backgroundColor = [UIColor clearColor];	
		headerCollectionName.lineBreakMode = UILineBreakModeTailTruncation;
		headerCollectionName.numberOfLines = 2;
		
		headerCollectionCallNumber = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 0.0, 200.0, heightCallNbr)];
		headerCollectionCallNumber.text = callNbr;
		headerCollectionCallNumber.font =  [UIFont fontWithName:STANDARD_FONT size:13];
		headerCollectionCallNumber.textColor = [UIColor colorWithHexString:@"#554C41"];
		headerCollectionCallNumber.backgroundColor = [UIColor clearColor];	
		headerCollectionCallNumber.lineBreakMode = UILineBreakModeTailTruncation;
		headerCollectionCallNumber.numberOfLines = 2;
		
		headerCollectionAvailVal = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 0.0, 200.0, heightAvailVal)];
		headerCollectionAvailVal.text = availVal;
		headerCollectionAvailVal.font =  [UIFont fontWithName:STANDARD_FONT size:13];
		headerCollectionAvailVal.textColor = [UIColor colorWithHexString:@"#554C41"];
		headerCollectionAvailVal.backgroundColor = [UIColor clearColor];	
		headerCollectionAvailVal.lineBreakMode = UILineBreakModeTailTruncation;
		headerCollectionAvailVal.numberOfLines = 2;
		
		return heightName + heightCallNbr + heightAvailVal + 3;

	}
	
	text1 = [statDict objectForKey:@"statMain"];
	text2 = [statDict objectForKey:@"callNumber"];
	
	
	/*if (height > 21) // one line
		height = 21;*/
	
	CGFloat height = [text1
					  sizeWithFont:[UIFont boldSystemFontOfSize:17]
					  constrainedToSize:CGSizeMake(280.0, 2000)         
					  lineBreakMode:UILineBreakModeWordWrap].height;
	
	CGFloat height2 = [text2
					   sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
					   constrainedToSize:CGSizeMake(280.0, 2000)         
					   lineBreakMode:UILineBreakModeWordWrap].height;
	
	return height + height2 + 5;
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
		openToday = [NSString stringWithFormat: @"Open today at %@", hrsToday];
	}
	
	[self setupLayout];

}

- (BOOL)request:(JSONAPIRequest *)request shouldDisplayAlertForError:(NSError *)error {
	
    return YES;
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error {

	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
														message:@"Could not retrieve information about today's open hours" 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

#pragma mark UIActionSheet setup

-(void) showActionSheet:(int)sectionIndex{
	
	showingSection = sectionIndex;
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
	
	NSDictionary * statDict = [availabilityCategories objectAtIndex:showingSection];
	
	int availCount = 0;
	availCount = [[statDict objectForKey:@"availCount"] intValue];
	
	int unavailCount = 0;
	unavailCount = [[statDict objectForKey:@"unavailCount"] intValue];
	
	int checkedOutCount = 0;
	checkedOutCount = [[statDict objectForKey:@"checkedOutCount"] intValue];
	
	int requestCount = 0;
	requestCount = [[statDict objectForKey:@"requestCount"] intValue];
	
	int scanAndDeliverCount = 0;
	scanAndDeliverCount = [[statDict objectForKey:@"scanAndDeliverCount"] intValue];

	NSMutableArray * items = [[NSMutableArray alloc] init];
	int indexCount =0;
	
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
		
	
	NSString * reqUrl = @"";
	if (buttonIndex == 0) {
		 NSLog(@"Request Item");
		
		for(NSDictionary * availD in items){
			if ([[availD objectForKey:@"canRequest"] isEqualToString:@"YES"])
				if ([[availD objectForKey:@"requestUrl"] length] > 0)
					reqUrl = [availD objectForKey:@"requestUrl"];
		}
       
    } else if (buttonIndex == 1) {
        NSLog(@"Scan & Deliver");
		
		for(NSDictionary * availD in items){
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

