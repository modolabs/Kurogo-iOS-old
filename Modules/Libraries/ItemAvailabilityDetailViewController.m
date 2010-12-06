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


#pragma mark -
#pragma mark Initialization


- (id)initWithStyle:(UITableViewStyle)style 
			library:(Library *)lib 
			   item:(LibraryItem *)libraryItem 
		 categories:(NSArray *)availCategories
allLibrariesWithItem: (NSArray *) allLibraries
			 index :(int) index	{
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
		
		library = [lib retain];
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
	NSString * libraryName = library.name; //@"Cabot Science Library ";
	NSString * openToday = @"Open Today at xxxxxxxxxxxxxxxxxx";
	CGFloat height1 = [libraryName
					  sizeWithFont:[UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE]
					  constrainedToSize:CGSizeMake(350, 2000)         
					   lineBreakMode:UILineBreakModeWordWrap].height;
						
	CGFloat height2 = [openToday
					 sizeWithFont:[UIFont fontWithName:COURSE_NUMBER_FONT size:13]
					 constrainedToSize:CGSizeMake(300, 20)         
					 lineBreakMode:UILineBreakModeWordWrap].height;
	
	CGFloat height = height1 + height2;
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 0.0, 350.0, height1)];
	label.text = libraryName;
	label.font = [UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE];
	label.textColor = [UIColor colorWithHexString:@"#1a1611"];
	label.backgroundColor = [UIColor clearColor];	
	label.lineBreakMode = UILineBreakModeWordWrap;
	label.numberOfLines = 5;
	

	UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, height1 + 5.0, 300.0, height2)];
	label2.text = openToday;
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
	
/*	if ([sender isKindOfClass:[UISegmentedControl class]]) {
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
				
				Library * temp = (Library *)[tempDict objectForKey:@"library"];
				
				NSDictionary * tempItemAvail = (NSDictionary *)[tempDict objectForKey:@"availabilityCategories"];
				
				library = [temp retain];
				availabilityCategories = [tempItemAvail retain];
				currentIndex = tempLibIndex;
				
				[self viewWillAppear:YES];															
				
			}			
		}
	}	*/
}




#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [availabilityCategories count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	
	int rows = 0;
	NSDictionary * availDict = [availabilityCategories objectAtIndex:indexPath.section];

	
    return 3;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSDictionary * availDict = [availabilityCategories objectAtIndex:indexPath.section];
	
	if (indexPath.row == 0) // available
		cell.textLabel.text = [NSString stringWithFormat:@"%d available", [[availDict objectForKey:@"available"] intValue]];
	
	else if (indexPath.row == 1) {// checked out
		cell.textLabel.text = [NSString stringWithFormat:@"%d checked out", [[availDict objectForKey:@"checkedOut"] intValue]];
		
		if ([availDict objectForKey:@"checkedOut"] > 0)
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	else if (indexPath.row == 2) // unavailable
		cell.textLabel.text = [NSString stringWithFormat:@"%d unavailable", [[availDict objectForKey:@"unavailable"] intValue]];
		
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
	
	
    return cell;
}




#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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
	
	NSDictionary * tempDict = [availabilityCategories objectAtIndex:section];
	
	UILabel * headerLabel1;
	UILabel * headerLabel2;
		
	text1 = [tempDict objectForKey:@"type"];
	text2 = [tempDict objectForKey:@"callNumber"];
	
	CGFloat height = [text1
						  sizeWithFont:[UIFont boldSystemFontOfSize:17]
						  constrainedToSize:CGSizeMake(200, 2000)         
						  lineBreakMode:UILineBreakModeWordWrap].height;
		
		headerLabel1 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 0.0, 150.0, height)];
		headerLabel1.text = text1;
		headerLabel1.font = [UIFont boldSystemFontOfSize:17];
		headerLabel1.textColor = [UIColor colorWithHexString:@"#554C41"];
		headerLabel1.backgroundColor = [UIColor clearColor];	
		headerLabel1.lineBreakMode = UILineBreakModeTailTruncation;
		headerLabel1.numberOfLines = 1;

	
	headerLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(170.0, 0.0, 170.0, height)];
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
	
	NSDictionary * tempDict = [availabilityCategories objectAtIndex:section];

	text1 = [tempDict objectForKey:@"type"];
	
	CGFloat height = [text1
					  sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:17]
					  constrainedToSize:CGSizeMake(200, 2000)         
					  lineBreakMode:UILineBreakModeWordWrap].height;
	
	
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


@end

