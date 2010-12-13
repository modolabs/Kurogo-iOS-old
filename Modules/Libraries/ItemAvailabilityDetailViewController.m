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


@implementation ItemAvailabilityDetailViewController
@synthesize parentViewApiRequest;


#pragma mark -
#pragma mark Initialization


- (id)initWithStyle:(UITableViewStyle)style 
			libName:(NSString *)libName
			  libId:(NSString *) libId
			   item:(LibraryItem *)libraryItem 
		 categories:(NSArray *)availCategories
allLibrariesWithItem: (NSArray *) allLibraries
			 index :(int) index{
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
		
		libraryName = libName;
		libraryId = libId;
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
	//NSString * libraryName = libraryName; //@"Cabot Science Library ";
	//NSString * openToday = @"Open Today at xxxxxxxxxxxxxxxxxx";
	CGFloat height1 = [libraryName
					  sizeWithFont:[UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE]
					  constrainedToSize:CGSizeMake(300, 2000)         
					   lineBreakMode:UILineBreakModeWordWrap].height;
						
	CGFloat height2 = [openToday
					 sizeWithFont:[UIFont fontWithName:COURSE_NUMBER_FONT size:13]
					 constrainedToSize:CGSizeMake(300, 20)         
					 lineBreakMode:UILineBreakModeWordWrap].height;
	
	CGFloat height = height1 + height2;
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 0.0, 300.0, height1)];
	label.text = libraryName;
	label.font = [UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE];
	label.textColor = [UIColor colorWithHexString:@"#1a1611"];
	label.backgroundColor = [UIColor clearColor];	
	label.lineBreakMode = UILineBreakModeWordWrap;
	label.numberOfLines = 5;
	
	NSString * openTodayString;
	if (nil == openToday)
		openTodayString = @"";
	else {
		openTodayString = openToday;
	}

	
	UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, height1 + 5.0, 300.0, height2)];
	label2.text = openTodayString;
	label2.font = [UIFont fontWithName:COURSE_NUMBER_FONT
								  size:13];
	label2.textColor = [UIColor colorWithHexString:@"#666666"];
	label2.backgroundColor = [UIColor clearColor];	
	label2.lineBreakMode = UILineBreakModeWordWrap;
	label2.numberOfLines = 1;
	
	headerView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.frame.size.width, height + 5.0)] autorelease];
	[headerView addSubview:label];
	[headerView addSubview:label2];
	
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
				NSString * type = [tempDict objectForKey:@"type"];
				
				NSArray * itemsByStat = (NSArray *)[tempDict objectForKey:@"itemsByStat"];

					
					
					apiRequest = [[JSONAPIRequest alloc] initWithJSONAPIDelegate:self];
					
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
					
						currentIndex = tempLibIndex;
						libraryName = libName;
						libraryId = libId;
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
	
	BOOL availableIsYellow = NO;
	for(NSDictionary * availItemDict in availableItems){
		
		NSString * canRequest = [availItemDict objectForKey:@"canRequest"];
		
		if ([canRequest isEqualToString:@"YES"]) {
			availableIsYellow = YES;
			break;
		}
	}
	
	BOOL checkedOutCanRequest = NO;
	for(NSDictionary * availItemDict in checkedOutItems){
		
		NSString * canRequest = [availItemDict objectForKey:@"canRequest"];
		
		if ([canRequest isEqualToString:@"YES"]) {
			checkedOutCanRequest = YES;
			break;
		}
	}
	
	
	
	UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(230.0, cell.frame.size.height/2 - 10, 50.0, 20.0)];
	label2.text = @"Request";
	label2.font = [UIFont fontWithName:COURSE_NUMBER_FONT
								  size:13];
	label2.textColor = [UIColor colorWithHexString:@"#666666"];
	label2.backgroundColor = [UIColor clearColor];	
	label2.lineBreakMode = UILineBreakModeWordWrap;
	label2.numberOfLines = 1;
	
	if (indexPath.row == 0) {// available
		
		if (availCount > 0) {
			cell.textLabel.text = [NSString stringWithFormat:@"%d available", availCount];
			UIImage *image;
			if (availableIsYellow == YES) {
				//image = [UIImage imageNamed:@"dining/dining-status-open-w-restrictions.png"];
				//cell.imageView.image = image;
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				
				[cell addSubview:label2];
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
				[cell addSubview:label2];
			}
			
			UIImage *image = [UIImage imageNamed:@"dining/dining-status-open-w-restrictions.png"];
			cell.imageView.image = image;
			
			
		}
		
		else if (unavailCount > 0){
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
				[cell addSubview:label2];
			}
			
			UIImage *image = [UIImage imageNamed:@"dining/dining-status-open-w-restrictions.png"];
			cell.imageView.image = image;
			
			
		}
		
		else if (unavailCount > 0){
			cell.textLabel.text = [NSString stringWithFormat:@"%d unavailable", unavailCount];
			UIImage *image = [UIImage imageNamed:@"dining/dining-status-closed.png"];
			cell.imageView.image = image;
		}
		
	}
	
	else if (indexPath.row == 2) {// unavailable
		
		if (unavailCount > 0) {
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
	NSString * isUnAvailable = [itemForRow objectForKey:@"unavailable"];
	NSString * isAvailable = [itemForRow objectForKey:@"available"];
	
	NSString * status = @"";
	NSString * color = @"";
	
	if ([isAvailable isEqualToString:@"YES"]){
		status = @"Available";
		color = @"green";
	}
	
	else if ([canRequest isEqualToString:@"YES"]){
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
	
	if ([canRequest isEqualToString:@"YES"])
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
	
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	RequestWebViewModalViewController *modalVC = [[RequestWebViewModalViewController alloc] initWithRequestUrl:@"http://www.bbc.com"];

	//[self.navigationController pushViewController:modalVC animated:YES];
	//[modalVC release];
	
	[appDelegate presentAppModalViewController:modalVC animated:YES];
	[modalVC release];
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
		
		headerCollectionCallNumber = [[UILabel alloc] initWithFrame:CGRectMake(12.0, heightName + 3, 200.0, heightCallNbr)];
		headerCollectionCallNumber.text = callNbr;
		headerCollectionCallNumber.font =  [UIFont fontWithName:STANDARD_FONT size:13];
		headerCollectionCallNumber.textColor = [UIColor colorWithHexString:@"#554C41"];
		headerCollectionCallNumber.backgroundColor = [UIColor clearColor];	
		headerCollectionCallNumber.lineBreakMode = UILineBreakModeTailTruncation;
		headerCollectionCallNumber.numberOfLines = 2;
		
		headerCollectionAvailVal = [[UILabel alloc] initWithFrame:CGRectMake(12.0, heightName + 3 + heightCallNbr + 3, 200.0, heightAvailVal)];
		headerCollectionAvailVal.text = availVal;
		headerCollectionAvailVal.font =  [UIFont fontWithName:STANDARD_FONT size:13];
		headerCollectionAvailVal.textColor = [UIColor colorWithHexString:@"#554C41"];
		headerCollectionAvailVal.backgroundColor = [UIColor clearColor];	
		headerCollectionAvailVal.lineBreakMode = UILineBreakModeTailTruncation;
		headerCollectionAvailVal.numberOfLines = 2;
		
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


@end

