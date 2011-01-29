//
//  BookmarkedLibItemListView.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 12/7/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "BookmarkedLibItemListView.h"
#import "MITUIConstants.h"
#import "CoreDataManager.h"
#import "LibrariesMultiLineCell.h"
#import "LibItemDetailViewController.h"

@implementation BookmarkedLibItemListView


#pragma mark -
#pragma mark Initialization

NSInteger bookmarkedItemsNameSorted(id item1, id item2, void *context);

NSInteger bookmarkedItemsNameSorted(id item1, id item2, void *context) {
	
	LibraryItem * libItem1 = (LibraryItem *)item1;
	LibraryItem * libItem2 = (LibraryItem *)item2;
	
	return [libItem1.title compare:libItem2.title];
}

- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
		
		NSPredicate *bookmarkPred = [NSPredicate predicateWithFormat:@"isBookmarked == YES"];
		NSArray *tempArray = [CoreDataManager objectsForEntity:LibraryItemEntityName matchingPredicate:bookmarkPred];
		
		bookmarkedItems = [[tempArray sortedArrayUsingFunction:bookmarkedItemsNameSorted context:self] retain];
		
		bookmarkedItemsDictionaryWithIndexing = [[NSMutableDictionary alloc] init];
		for (int i=0; i < [bookmarkedItems count]; i++){
			[bookmarkedItemsDictionaryWithIndexing setObject:[bookmarkedItems objectAtIndex:i] forKey:[NSString stringWithFormat:@"%d", i+1]];
		}
		
		self.tableView.delegate = self;
		self.tableView.dataSource = self;
    }
    return self;
}



#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	NSPredicate *bookmarkPred = [NSPredicate predicateWithFormat:@"isBookmarked == YES"];
	NSArray *tempArray = [CoreDataManager objectsForEntity:LibraryItemEntityName matchingPredicate:bookmarkPred];
	
	bookmarkedItems = [[tempArray sortedArrayUsingFunction:bookmarkedItemsNameSorted context:self] retain];
	
	bookmarkedItemsDictionaryWithIndexing = [[NSMutableDictionary alloc] init];
	for (int i=0; i < [bookmarkedItems count]; i++){
		[bookmarkedItemsDictionaryWithIndexing setObject:[bookmarkedItems objectAtIndex:i] forKey:[NSString stringWithFormat:@"%d", i+1]];
	}
	
	[self.tableView reloadData];
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
#pragma mark Table view delegate

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
	LibraryItem * libItem = (LibraryItem *)[bookmarkedItems objectAtIndex:indexPath.row];
	
	BOOL displayImage = NO;
	if ([libItem.formatDetail isEqualToString:@"Image"])
		displayImage = YES;
	
	LibItemDetailViewController *vc = [[LibItemDetailViewController alloc]  initWithStyle:UITableViewStyleGrouped
																			  libraryItem:libItem
																				itemArray:bookmarkedItemsDictionaryWithIndexing
																		  currentItemIdex:indexPath.row
																			 imageDisplay:displayImage];
    
    [self.navigationController pushViewController:vc animated:YES];
	
	[vc release];
	
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [bookmarkedItems count];
}


- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	
	LibrariesMultiLineCell *cell = (LibrariesMultiLineCell *)[aTableView dequeueReusableCellWithIdentifier:@"zbcryetee"];
	if(cell == nil) {
		cell = [[[LibrariesMultiLineCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
											  reuseIdentifier:@"HollisSearch"] 
				autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	
	cell.textLabelNumberOfLines = 2;
	cell.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
	cell.textLabel.font = [UIFont fontWithName:STANDARD_FONT size:STANDARD_CONTENT_FONT_SIZE];
	cell.detailTextLabel.font = [UIFont fontWithName:STANDARD_FONT size:13];
	cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	
	LibraryItem * libItem =  (LibraryItem *)[bookmarkedItems objectAtIndex:indexPath.row];
	NSString *cellText;
	NSString *detailText;
	
	if (nil != libItem) {
		cellText = libItem.title;
		
		if (([libItem.year length] == 0) && ([libItem.author length] ==0))
			detailText = @"       ";
		
		else if (([libItem.year length] == 0) && ([libItem.author length] > 0))
			detailText = [NSString stringWithFormat:@"%@", libItem.author];
		
		else if (([libItem.year length] > 0) && ([libItem.author length] == 0))
			detailText = [NSString stringWithFormat:@"%@", libItem.year];
		
		else if (([libItem.year length] > 0) && ([libItem.author length] > 0))
			detailText = [NSString stringWithFormat:@"%@ | %@", libItem.year, libItem.author];
		
		else {
			detailText = [NSString stringWithFormat:@"       "];
		}
	}
	else {
		cellText = @"";
		detailText = @"";
	}
	
	
	cell.textLabel.text = [NSString stringWithFormat:@"%d. %@", 
						   indexPath.row + 1, cellText];
	cell.detailTextLabel.text = detailText;
	cell.detailTextLabel.textColor = [UIColor colorWithHexString:@"#554C41"];
	
	NSString * imageString;
	
	if (nil != libItem.formatDetail) {
		
		if ([libItem.formatDetail isEqualToString:@"Recording"])
			imageString = @"soundrecording.png";
		
		else if ([libItem.formatDetail isEqualToString:@"Image"])
			imageString = @"image.png";
		
		else if ([libItem.formatDetail isEqualToString:@"Map"])
			imageString = @"map.png";
		
		else if ([libItem.formatDetail isEqualToString:@"Journal / Serial"])
			imageString = @"journal.png";
		
		else if ([libItem.formatDetail isEqualToString:@"Movie"])
			imageString = @"video.png";
		
		else {
			imageString = @"book.png";
		}
		UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"libraries/%@", imageString]];
		cell.imageView.image = image;
	}
	return cell;
}

- (CGFloat) tableView: (UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath {
	//return [StellarClassTableCell cellHeightForTableView:tableView class:[self.lastResults objectAtIndex:indexPath.row]];
	
	UITableViewCellAccessoryType accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	LibraryItem * libItem =  (LibraryItem *)[bookmarkedItems objectAtIndex:indexPath.row];
	NSString *cellText;
	NSString *detailText;
	
	if (nil != libItem) {
		cellText = [NSString stringWithFormat:@"%d. %@", 
					indexPath.row + 1, libItem.title];
		
		if (([libItem.year length] == 0) && ([libItem.author length] ==0))
			detailText = @"         ";
		
		else if (([libItem.year length] == 0) && ([libItem.author length] > 0))
			detailText = [NSString stringWithFormat:@"%@", libItem.author];
		
		else if (([libItem.year length] > 0) && ([libItem.author length] == 0))
			detailText = [NSString stringWithFormat:@"%@", libItem.year];
		
		else if (([libItem.year length] > 0) && ([libItem.author length] > 0))
			detailText = [NSString stringWithFormat:@"%@ | %@", libItem.year, libItem.author];
		
		else {
			detailText = [NSString stringWithFormat:@"      "];
		}
		
	}
	else {
		cellText = @"";
		detailText = @"";
	}
	UIFont *detailFont = [UIFont systemFontOfSize:13];

	return [LibrariesMultiLineCell heightForCellWithStyle:UITableViewCellStyleSubtitle
												tableView:tableView 
													 text:cellText
											 maxTextLines:2
											   detailText:detailText
										   maxDetailLines:2
													 font:[UIFont fontWithName:STANDARD_FONT size:STANDARD_CONTENT_FONT_SIZE]
											   detailFont:detailFont
											accessoryType:accessoryType
												cellImage:YES];
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

