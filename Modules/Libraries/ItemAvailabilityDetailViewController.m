//
//  ItemAvailabilityDetailViewController.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 12/6/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "ItemAvailabilityDetailViewController.h"
#import "MITUIConstants.h"


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

	
    return row;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
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




#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
		[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
    // Navigation logic may go here. Create and push another view controller.
	/*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
}

- (UIView *)tableView: (UITableView *)tableView viewForHeaderInSection: (NSInteger)section{
	
	UIView * view;
	view = nil;
	NSString * text1 = @"";
	NSString * text2 = @"";
	
	NSDictionary * statDict = [availabilityCategories objectAtIndex:section];
	
	UILabel * headerLabel1;
	UILabel * headerLabel2;
		
	text1 = [statDict objectForKey:@"statMain"];
	text1 = [text1 stringByReplacingCharactersInRange:
							 NSMakeRange(0,1) withString:[[text1 substringToIndex:1] capitalizedString]];
	text2 = [statDict objectForKey:@"callNumber"];
	
	CGFloat height = [text1
						  sizeWithFont:[UIFont boldSystemFontOfSize:17]
						  constrainedToSize:CGSizeMake(150, 2000)         
						  lineBreakMode:UILineBreakModeWordWrap].height;
	
	if (height > 21)
		height = 21;
		
		headerLabel1 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 0.0, 150.0, height)];
		headerLabel1.text = text1;
		headerLabel1.font = [UIFont boldSystemFontOfSize:17];
		headerLabel1.textColor = [UIColor colorWithHexString:@"#554C41"];
		headerLabel1.backgroundColor = [UIColor clearColor];	
		headerLabel1.lineBreakMode = UILineBreakModeTailTruncation;
		headerLabel1.numberOfLines = 1;

	
	headerLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(180.0, 0.0, 140.0, height)];
	headerLabel2.text = text2;
	headerLabel2.font = [UIFont fontWithName:STANDARD_FONT size:13];
	headerLabel2.textColor = [UIColor colorWithHexString:@"#554C41"];
	headerLabel2.backgroundColor = [UIColor clearColor];	
	headerLabel2.lineBreakMode = UILineBreakModeTailTruncation;
	headerLabel2.numberOfLines = 1;
		
	view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, height)];
	[view addSubview:headerLabel1];
	[view addSubview:headerLabel2];

	
	return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {

	NSString * text1 = @"";
	
	NSDictionary * statDict = [availabilityCategories objectAtIndex:section];
	
	text1 = [statDict objectForKey:@"statMain"];
	
	CGFloat height = [text1
					  sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:17]
					  constrainedToSize:CGSizeMake(150, 2000)         
					  lineBreakMode:UILineBreakModeWordWrap].height;
	
	
	if (height > 21) // one line
		height = 21;
	
	return height + 5;
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

