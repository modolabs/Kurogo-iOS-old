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

@class LibItemDetailCell;

@implementation LibItemDetailViewController
@synthesize bookmarkButtonIsOn;


#pragma mark -
#pragma mark Initialization

-(id) initWithStyle:(UITableViewStyle)style 
			  title:(NSString *)title 
			 author: (NSString *) authorName 
	   otherDetail1:(NSString *) otherDetail1 
	   otherDetail2:(NSString *) otherDetail2 
	   otherDetail3: (NSString *) otherDetail3 
		  libraries:(NSDictionary *)libraries; {
	
	self = [super initWithStyle:style];
	
	if (self) {
		
		itemTitle = title;
		author = authorName;
		otherDetailLine1 = otherDetail1;
		otherDetailLine2 = otherDetail2;
		otherDetailLine3 = otherDetail3;
		librariesWithItem = libraries;
		
		self.tableView.delegate = self;
		self.tableView.dataSource = self;
	}
	
	return self;
}


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
	
	UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:
																					[UIImage imageNamed:MITImageNameUpArrow],
																					[UIImage imageNamed:MITImageNameDownArrow], nil]];
	[segmentControl setMomentary:YES];
	[segmentControl addTarget:self action:@selector(showNextLibItem:) forControlEvents:UIControlEventValueChanged];
	segmentControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentControl.frame = CGRectMake(0, 0, 80.0, segmentControl.frame.size.height);
	UIBarButtonItem * segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView: segmentControl];
	self.navigationItem.rightBarButtonItem = segmentBarItem;
	[segmentControl release];
	[segmentBarItem release];

	CGFloat runningYDispacement = 0.0;
	CGFloat titleHeight = [itemTitle
						   sizeWithFont:[UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE]
						   constrainedToSize:CGSizeMake(300, 200)         
						   lineBreakMode:UILineBreakModeWordWrap].height;
	
	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 10.0, 300.0, titleHeight)];
	
	runningYDispacement += titleHeight;
	
	titleLabel.text = itemTitle;
	titleLabel.font = [UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE];
	titleLabel.textColor = [UIColor colorWithHexString:@"#1a1611"];
	titleLabel.backgroundColor = [UIColor clearColor];	
	titleLabel.lineBreakMode = UILineBreakModeWordWrap;
	titleLabel.numberOfLines = 3;
	
	
	CGFloat authorHeight = [author
						   sizeWithFont:[UIFont fontWithName:COURSE_NUMBER_FONT size:15]
						   constrainedToSize:CGSizeMake(200, 20)         
						   lineBreakMode:UILineBreakModeWordWrap].height;
	
	UILabel *authorLabel = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 20 + runningYDispacement, 200.0, authorHeight)];
	
	runningYDispacement += authorHeight;
	
	authorLabel.text = author;
	authorLabel.font = [UIFont fontWithName:COURSE_NUMBER_FONT size:14];
	authorLabel.textColor = [UIColor redColor];
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
	
	mapButton = [UIButton buttonWithType:UIButtonTypeCustom];
	mapButton.frame = CGRectMake(self.tableView.frame.size.width - 60.0 , runningYDispacement - 15, 50.0, 50.0);
	mapButton.enabled = YES;
	[mapButton setImage:[UIImage imageNamed:@"maps/map_pin_complete.png"] forState:UIControlStateNormal];
	[mapButton setImage:[UIImage imageNamed:@"maps/map_pin_complete.png"] forState:(UIControlStateNormal | UIControlStateHighlighted)];
	[mapButton setImage:[UIImage imageNamed:@"maps/map_pin_complete.png"] forState:UIControlStateSelected];
	[mapButton setImage:[UIImage imageNamed:@"maps/map_pin_complete.png"] forState:(UIControlStateSelected | UIControlStateHighlighted)];
	[mapButton addTarget:self action:@selector(mapButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	
	
	CGFloat detailHeight1 = [otherDetailLine1
							sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
							constrainedToSize:CGSizeMake(250, 20)         
							lineBreakMode:UILineBreakModeWordWrap].height;
	
	UILabel *detailLabel1 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 20 + runningYDispacement, 250.0, detailHeight1)];
	
	runningYDispacement += detailHeight1;
	
	detailLabel1.text = otherDetailLine1;
	detailLabel1.font = [UIFont fontWithName:STANDARD_FONT size:13];
	detailLabel1.textColor = [UIColor colorWithHexString:@"#554C41"];
	detailLabel1.backgroundColor = [UIColor clearColor];	
	detailLabel1.lineBreakMode = UILineBreakModeTailTruncation;
	detailLabel1.numberOfLines = 1;
	
	CGFloat detailHeight2 = [otherDetailLine2
							 sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
							 constrainedToSize:CGSizeMake(250, 20)         
							 lineBreakMode:UILineBreakModeWordWrap].height;
	
	UILabel *detailLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 20 + runningYDispacement, 250.0, detailHeight2)];
	
	runningYDispacement += detailHeight2;
	
	detailLabel2.text = otherDetailLine2;
	detailLabel2.font = [UIFont fontWithName:STANDARD_FONT size:13];
	detailLabel2.textColor = [UIColor colorWithHexString:@"#554C41"];
	detailLabel2.backgroundColor = [UIColor clearColor];	
	detailLabel2.lineBreakMode = UILineBreakModeTailTruncation;
	detailLabel2.numberOfLines = 1;
	
	CGFloat detailHeight3 = [otherDetailLine1
							 sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:13]
							 constrainedToSize:CGSizeMake(250, 20)         
							 lineBreakMode:UILineBreakModeWordWrap].height;
	
	UILabel *detailLabel3 = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 20 + runningYDispacement, 250.0, detailHeight3)];
	
	runningYDispacement += detailHeight3;
	
	detailLabel3.text = otherDetailLine3;
	detailLabel3.font = [UIFont fontWithName:STANDARD_FONT size:13];
	detailLabel3.textColor = [UIColor colorWithHexString:@"#554C41"];
	detailLabel3.backgroundColor = [UIColor clearColor];	
	detailLabel3.lineBreakMode = UILineBreakModeTailTruncation;
	detailLabel3.numberOfLines = 1;
	
	
	UIView * headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 
																   15 + runningYDispacement)];

	[headerView addSubview:titleLabel];
	[headerView addSubview:authorLabel];
	[headerView addSubview:bookmarkButton];
	[headerView addSubview:mapButton];
	[headerView addSubview:detailLabel1];
	[headerView addSubview:detailLabel2];
	[headerView addSubview:detailLabel3];
	
	self.tableView.tableHeaderView = [[UIView alloc]
									  initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, headerView.frame.size.height + 10)];
	[self.tableView.tableHeaderView addSubview:headerView];
	
	[self.tableView applyStandardColors];
	
	
}

#pragma mark User Interaction

-(void) showNextLibItem: (id) sender {
}

-(void) mapButtonPressed: (id) sender {
}


-(void) bookmarkButtonToggled: (id) sender {
	
	BOOL newBookmarkButtonStatus = !bookmarkButton.selected;
	
	if (newBookmarkButtonStatus) {
		//[StellarModel saveClassToFavorites:stellarClass];
		bookmarkButton.selected = YES;
	}
	
	else {
		//[StellarModel removeClassFromFavorites:stellarClass];
		bookmarkButton.selected = NO;
	}
	
	
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
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    
	if (section == 0)
		return 1;
	
	else if (section == 1)
		return [librariesWithItem count];
	
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
		
		cell.textLabel.text = @"Available Online";
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
		return cell;
	}
	
	else if (indexPath.section == 1) {
		NSDictionary * tempDict = [[NSDictionary alloc] initWithObjectsAndKeys:
		 @"available", @"1 of 2 available - regular loan",
		 @"unavailable", @"2 of 2 available - in-library user",
		 @"request", @"2 of 2 availavle - depository", nil];
		 
		
		static NSString *CellIdentifier1 = @"CellLib";
		
		LibItemDetailCell *cell1 = (LibItemDetailCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
		if (cell1 == nil) {
			cell1 = [[[LibItemDetailCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
											 reuseIdentifier:CellIdentifier1 
											itemAvailability:tempDict] autorelease];
		}
		
		cell1.textLabel.text = [[librariesWithItem allKeys] objectAtIndex:indexPath.row];
 
		cell1.detailTextLabel.text = [librariesWithItem objectForKey:[[librariesWithItem allKeys] objectAtIndex:indexPath.row]];
		cell1.detailTextLabel.textColor = [UIColor colorWithHexString:@"#554C41"];
		

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
	else if (indexPath.section == 1) {
		cellText =  [[librariesWithItem allKeys] objectAtIndex:indexPath.row];
		detailText = [librariesWithItem objectForKey:[[librariesWithItem allKeys] objectAtIndex:indexPath.row]];
		accessoryType = UITableViewCellAccessoryDisclosureIndicator;		
	}
	
	CGFloat height = [cellText
					  sizeWithFont:[UIFont fontWithName:COURSE_NUMBER_FONT size:COURSE_NUMBER_FONT_SIZE]
					  constrainedToSize:CGSizeMake(self.tableView.frame.size.width*2/3, 500)         
					  lineBreakMode:UILineBreakModeWordWrap].height;
	
	NSDictionary * tempDict = [[NSDictionary alloc] initWithObjectsAndKeys:
							   @"available", @"1 of 2 available - regular loan",
							   @"unavailable", @"2 of 2 available - in-library user",
							   @"request", @"2 of 2 availavle - depository", nil];
	
	if (indexPath.section == 1)
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
						  itemAvailabilityDictionary: tempDict];
	
	return height + 20;

}



#pragma mark -
#pragma mark Table view delegate
- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
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

