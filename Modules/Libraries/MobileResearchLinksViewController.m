//
//  MobileResearchLinksViewController.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 12/17/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "MobileResearchLinksViewController.h"
#import "MITUIConstants.h"
#import "Constants.h"
#import "LibrariesMultiLineCell.h"

@implementation MobileResearchLinksViewController


#pragma mark -
#pragma mark Initialization

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

-(id) init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization.
    }
    return self;
}


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	NSDictionary * ebscoLinks = [[[NSDictionary alloc] initWithObjectsAndKeys:
								 @"http://nrs.harvard.edu/urn-3:hul.eresource:mobebasp", @"Academic Search Premier",
								 @"http://nrs.harvard.edu/urn-3:hul.eresource:mobebbus", @"Business Source Complete",
								 @"http://nrs.harvard.edu/urn-3:hul.eresource:mobeberi", @"ERIC",
								 @"http://nrs.harvard.edu/urn-3:hul.eresource:mobebhis", @"Historical Abstracts",
								 @"http://nrs.harvard.edu/urn-3:hul.eresource:mobebmla", @"MLA Int'l Bibliography",
								 @"http://nrs.harvard.edu/urn-3:hul.eresource:mobebpsy", @"PsycINFO",
								  @"http://nrs.harvard.edu/urn-3:hul.eresource:ebscomob", @"Complete EBSCO list", nil] retain];
	
	
	textAndLinksDictionary = [[[NSDictionary alloc] initWithObjectsAndKeys:
							  @"http://books.google.com/m", @"Google Book Search",
							  @"http://nrs.harvard.edu/urn-3:hul.eresource:gscholar", @"Google Scholar-Standard version",
							  ebscoLinks, @"EBSCO Links",
							  @"http://pubmedhh.nlm.nih.gov/", @"PubMed-Limited full text",
							   @"http://www.worldcat.org/m/", @"WorldCat", nil] retain];
	
	textsArray = [[[NSArray alloc] initWithObjects:
				  @"Google Book Search",
				  @"Google Scholar-Standard version",
				  @"EBSCO Links",
				  @"PubMed-Limited full text",
				   @"WorldCat", nil] retain];
	
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	
	[self.tableView applyStandardColors];
	
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
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [textsArray count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    
	//NSArray * allKeys = [textAndLinksDictionary allKeys];
	
	if ([[textAndLinksDictionary objectForKey:[textsArray objectAtIndex:section]] isKindOfClass:[NSDictionary class]]){
		return [[((NSDictionary *)[textAndLinksDictionary objectForKey:[textsArray objectAtIndex:section]]) allKeys] count];
	}

	return 1;

}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cellruewuruwer";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
	//NSArray * allKeys = [textAndLinksDictionary allKeys];
	
	NSString * cellText = @"";
	
	if ([[textAndLinksDictionary objectForKey:[textsArray objectAtIndex:indexPath.section]] isKindOfClass:[NSDictionary class]]){
		NSDictionary * tempDict = (NSDictionary *)[textAndLinksDictionary objectForKey:[textsArray objectAtIndex:indexPath.section]];
		
		cellText = [[tempDict allKeys] objectAtIndex:indexPath.row];
	}
	else {
		cellText = [textsArray objectAtIndex:indexPath.section];
	}

	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	cell.accessoryView =  [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
	
	NSArray *chunks = [cellText componentsSeparatedByString: @"-"];
	
	if ([chunks count] > 1) {
		static NSString *CellIdentifier1 = @"Cellkfkwfkrw";
		
		LibrariesMultiLineCell *cell1 = (LibrariesMultiLineCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
		if (cell1 == nil) {
			cell1 = [[[LibrariesMultiLineCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier1] autorelease];
		}
		
		cell1.textLabel.text = [chunks objectAtIndex:0];
		cell1.detailTextLabel.text = [chunks objectAtIndex:1];
		
		return cell1;
	}
	
	else {
		cell.textLabel.text = cellText;
	}

    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{	
	NSString *cellText = nil;
	NSString *detailText = nil;

	
	cellText = @"";
	
	if ([[textAndLinksDictionary objectForKey:[textsArray objectAtIndex:indexPath.section]] isKindOfClass:[NSDictionary class]]){
		NSDictionary * tempDict = (NSDictionary *)[textAndLinksDictionary objectForKey:[textsArray objectAtIndex:indexPath.section]];
		
		cellText = [[tempDict allKeys] objectAtIndex:indexPath.row];
	}
	else {
		cellText = [textsArray objectAtIndex:indexPath.section];
	}
	
	
	NSArray *chunks = [cellText componentsSeparatedByString: @"-"];
	
	if ([chunks count] > 1) {
		cellText = [chunks objectAtIndex:0];
		detailText = [chunks objectAtIndex:1];

	}


			
	return [LibrariesMultiLineCell heightForCellWithStyle:UITableViewCellStyleSubtitle
														tableView:tableView 
															 text:cellText
													 maxTextLines:1
													   detailText:detailText
												   maxDetailLines:1
															 font:nil 
													   detailFont:nil
													accessoryType:UITableViewCellAccessoryDisclosureIndicator
														cellImage:NO];
}

- (NSString *) tableView: (UITableView *)tableView titleForHeaderInSection: (NSInteger)section {

	if ([[textAndLinksDictionary objectForKey:[textsArray objectAtIndex:section]] isKindOfClass:[NSDictionary class]]){
		
		return [textsArray objectAtIndex:section];
	}
	return nil;
}

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	
	if ([[textAndLinksDictionary objectForKey:[textsArray objectAtIndex:section]] isKindOfClass:[NSDictionary class]]){
		
		return [UITableView groupedSectionHeaderWithTitle:[textsArray objectAtIndex:section]];
	}
	return nil;
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return GROUPED_SECTION_HEADER_HEIGHT - 3;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	NSString * urlString = @"";
	
	if ([[textAndLinksDictionary objectForKey:[textsArray objectAtIndex:indexPath.section]] isKindOfClass:[NSDictionary class]]){
		NSDictionary * tempDict = (NSDictionary *)[textAndLinksDictionary objectForKey:[textsArray objectAtIndex:indexPath.section]];
		
		urlString = [tempDict objectForKey:[[tempDict allKeys] objectAtIndex:indexPath.row]];
	}
	else {
		urlString = [textAndLinksDictionary objectForKey:[textsArray objectAtIndex:indexPath.section]];
	}
	
	NSURL *urlToOpen = [NSURL URLWithString:urlString];
	if (urlToOpen && [[UIApplication sharedApplication] canOpenURL:urlToOpen]) {
		[[UIApplication sharedApplication] openURL:urlToOpen];
	}
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end

