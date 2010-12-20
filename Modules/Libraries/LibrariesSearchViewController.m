//
//  LibrariesSearchViewController.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/23/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "LibrariesSearchViewController.h"
#import "UITableView+MITUIAdditions.h"
#import "MITUIConstants.h"
#import "MITSearchDisplayController.h"
#import "LibrariesMultiLineCell.h"
#import "MITLoadingActivityView.h"
#import "LibItemDetailViewController.h"
#import "LibraryItem.h"
#import "CoreDataManager.h"

@class LibrariesMultiLineCell;

@implementation LibrariesSearchViewController

@synthesize lastResults;
@synthesize activeMode;

@synthesize searchTerms, searchResults, searchController;
@synthesize loadingView;
@synthesize searchBar = theSearchBar;

- (BOOL) isSearchResultsVisible {
	return hasSearchInitiated && activeMode;
}

- (id) initWithViewController: (LibrariesMainViewController *)controller{
	if(self = [super init]) {
		activeMode = NO;
		viewController = controller;
		
		hasSearchInitiated = NO;
		actualCount = 0;
		
		/*self.lastResults = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
								@"Freakonomics: A rogue economist explores the hidden economic bj bfdb fbdsfb", @"0",
								@"Freakonomics: A rogue economist explores the hidden economic bj bfdb fbdsfb", @"1",
								@"Freakonomics [sound recording]: A rogue economist explores the hidden economic bj bfdb fbdsfb", @"2",
								  @"From economics", @"3", nil];
		 */
		
		self.lastResults = [[NSMutableDictionary alloc] init];
		
		/*self.lastResultsOtherDetails = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
										@"2005 | Levitt, Steven D.", @"0",
										@"2006 | Levitt, Steven D.", @"1",
										@"2006 | Levitt, Steven D.", @"2",
										@"2009 | Fine, Benjamin and Bradford Elgin", @"3", nil];
		 */
		
		//_tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
		//_tableView.delegate = self;
		//_tableView.dataSource = self;
		
		//[self.view addSubview:_tableView];
	}
	return self;
}

- (void) dealloc {
	[lastResults release];
	[super dealloc];
}

-(void) viewDidLoad {
	
	if (nil == theSearchBar)
		theSearchBar = [[ModoSearchBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, NAVIGATION_BAR_HEIGHT)];
	
	theSearchBar.tintColor = SEARCH_BAR_TINT_COLOR;
	theSearchBar.placeholder = @"HOLLIS keyword search";
	theSearchBar.showsBookmarkButton = NO; // use custom bookmark button
	if ([self.searchTerms length] > 0)
		theSearchBar.text = self.searchTerms;
	
	if (nil == searchController)
		self.searchController = [[[MITSearchDisplayController alloc] initWithSearchBar:theSearchBar contentsController:self] autorelease];
	
	self.searchController.delegate = self;
	self.searchController.searchResultsDelegate = self;
	self.searchController.searchResultsDataSource = self;
	
	if (nil != viewController)
		theSearchBar.text = viewController.searchTerms;
	
    [self.view addSubview:theSearchBar];
	
    CGRect frame = CGRectMake(0.0, theSearchBar.frame.size.height,
                              self.view.frame.size.width,
                              self.view.frame.size.height - theSearchBar.frame.size.height);
	
	_tableView = nil;
	_tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
	
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _tableView.delegate = self;
    _tableView.dataSource = self;
	
	[self.view addSubview:_tableView];
	
	//if (nil != self.searchTerms)
	//	previousSearchTerm = self.searchTerms;
	
	/*else if (nil != theSearchBar.text)
		previousSearchTerm = theSearchBar.text;
	
	else
		previousSearchTerm = @"";
	 */
}

#pragma mark UITableViewDataSource methods

- (NSInteger) tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
	return [self.lastResults count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
/*	NSDictionary * tempDict = [[NSDictionary alloc] initWithObjectsAndKeys:
							   @"available", @"1 of 2 available - regular loan",
							   @"unavailable", @"2 of 2 available - in-library user",
							   @"request", @"2 of 2 availavle - depository", nil];
*/
	
	LibrariesMultiLineCell *cell = (LibrariesMultiLineCell *)[aTableView dequeueReusableCellWithIdentifier:@"HollisSearch"];
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
	
	LibraryItem * libItem = (LibraryItem *)[self.lastResults objectForKey:[NSString stringWithFormat:@"%d", indexPath.row+1]];
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
		UIImage *image = [UIImage imageNamed:imageString];
		cell.imageView.image = image;
	}
	return cell;
}

- (CGFloat) tableView: (UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath {
	//return [StellarClassTableCell cellHeightForTableView:tableView class:[self.lastResults objectAtIndex:indexPath.row]];
	
	UITableViewCellAccessoryType accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	LibraryItem * libItem = (LibraryItem *)[self.lastResults objectForKey:[NSString stringWithFormat:@"%d", indexPath.row+1]];
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
	
/*NSDictionary * tempDict = [[NSDictionary alloc] initWithObjectsAndKeys:
							   @"available", @"1 of 2 available - regular loan",
							   @"unavailable", @"2 of 2 available - in-library user",
							   @"request", @"2 of 2 availavle - depository", nil];
*/	
	
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

- (NSInteger) numberOfSectionsInTableView: (UITableView *)tableView {
	return 1;
}

- (NSString *) tableView: (UITableView *)tableView titleForHeaderInSection: (NSInteger)section {
	if([lastResults count]) {
		if (actualCount > [lastResults count])
			return [NSString stringWithFormat:@"Displaying %i of %d", [self.lastResults count], actualCount];
		
		return [NSString stringWithFormat:@"%i matches found", [self.lastResults count]];
	}
	return nil;
}

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString *headerTitle = nil;
	
	if([lastResults count]) {
		if (actualCount > [lastResults count])
			headerTitle =  [NSString stringWithFormat:@"Displaying %i of %d", [self.lastResults count], actualCount];
		else
			headerTitle = [NSString stringWithFormat:@"%i matches found", [self.lastResults count]];
		
		return [UITableView ungroupedSectionHeaderWithTitle:headerTitle];
	}
	return nil;
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return UNGROUPED_SECTION_HEADER_HEIGHT;
}

#pragma mark UITableViewDelegate methods

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
	LibraryItem * libItem = (LibraryItem *)[self.lastResults objectForKey:[NSString stringWithFormat:@"%d", indexPath.row+1]];
	


	
	/*NSDictionary * libraries = [[NSDictionary alloc] initWithObjectsAndKeys:
								@"152 yards away", @"Cabot Science Library",
								@"0.5 miles away", @"Baker Business School", nil];
	 */
	
	BOOL displayImage = NO;
	
	if ([libItem.formatDetail isEqualToString:@"Image"])
		displayImage = YES;
	
	LibItemDetailViewController *vc = [[LibItemDetailViewController alloc]  initWithStyle:UITableViewStyleGrouped
																				libraryItem:libItem
																				itemArray:self.lastResults
																		  currentItemIdex:indexPath.row
																			 imageDisplay:displayImage];
	
	api = [[JSONAPIRequest alloc] initWithJSONAPIDelegate:vc];
	
	BOOL requestSent = NO;
	
	if (displayImage == NO)
	 requestSent = [api requestObjectFromModule:@"libraries" 
									command:@"fullavailability"
						  parameters:[NSDictionary dictionaryWithObjectsAndKeys:libItem.itemId, @"itemid", nil]];
	
	else {
		requestSent = [api requestObjectFromModule:@"libraries" 
										   command:@"imagethumbnail"
										parameters:[NSDictionary dictionaryWithObjectsAndKeys:libItem.itemId, @"itemid", nil]];
	}

	if (requestSent == YES)
	{
		vc.title = @"Item Detail";
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


- (void)setupSearchController {
    if (!self.searchController) {
        self.searchController = [[MITSearchDisplayController alloc] initWithSearchBar:theSearchBar contentsController:self];
        self.searchController.delegate = self;
    }
}

- (void)hideToolBar {
    [UIView beginAnimations:@"searching" context:nil];
    [UIView setAnimationDuration:0.4];
    //_bookmarkButton.alpha = 0.0;
	theSearchBar.frame = CGRectMake(0, 0, self.view.frame.size.width, NAVIGATION_BAR_HEIGHT);
	// _toolBar.alpha = 0.0;
    [UIView commitAnimations];
}

- (void)restoreToolBar {
    [theSearchBar setShowsCancelButton:NO animated:YES];
    [UIView beginAnimations:@"searching" context:nil];
    [UIView setAnimationDuration:0.4];
	
    [UIView commitAnimations];
}


#pragma mark -
#pragma mark Search methods

- (void)beginExternalSearch:(NSString *)externalSearchTerms {
	self.searchTerms = externalSearchTerms;
	theSearchBar.text = self.searchTerms;
	
	//[self performSearch];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	self.searchResults = nil;
	// if they cancelled while waiting for loading
	if (requestWasDispatched) {
		//[api abortRequest];
		//[self cleanUpConnection];
	}
	[self restoreToolBar];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	//[_bookmarkButton removeFromSuperview];
	
	//if (nil != self.searchTerms)
	//	previousSearchTerm = self.searchTerms;
	
	self.searchTerms = searchBar.text;
	
	api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
	requestWasDispatched = [api requestObjectFromModule:@"libraries"
                                                command:@"search"
                                             parameters:[NSDictionary dictionaryWithObjectsAndKeys:self.searchTerms, @"q", nil]];
	
    if (requestWasDispatched) {
    } else {
        [self handleWarningMessage:@"Could not dispatch search" title:@"Search Failed"];
		[self restoreToolBar];
		//self.searchTerms = previousSearchTerm;
    }	
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
	[self setupSearchController]; // in case we got rid of it from a memory warning
    [self hideToolBar];
}

- (void)performSearch
{
	
}

- (void)presentSearchResults:(NSArray *)theSearchResults {
  /*  self.searchResults = theSearchResults;
    self.searchController.searchResultsTableView.frame = self.tableView.frame;
    [self.view addSubview:self.searchController.searchResultsTableView];
    [self.searchBar addDropShadow];
    [self.searchController.searchResultsTableView reloadData];*/
}

#pragma mark -
#pragma mark Connection methods

- (void)showLoadingView {
	// manually add loading view because we're not using the built-in data source table
	if (self.loadingView == nil) {
        self.loadingView = [[MITLoadingActivityView alloc] initWithFrame:_tableView.frame];
	}
	
	[_tableView addSubview:self.loadingView];
    [self.searchBar addDropShadow];
}

- (void)cleanUpConnection {
	requestWasDispatched = NO;
	[self.loadingView removeFromSuperview];	
}

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result {
    [self cleanUpConnection];
	
    if (result) {
        DLog(@"%@", [result description]);
        
        if ([result isKindOfClass:[NSArray class]]) {
			[self.searchBar addDropShadow];
		
			if ([result count] == 0) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil 
																message:@"No results found"
															   delegate:self
													  cancelButtonTitle:@"OK" 
													  otherButtonTitles:nil]; 
				[alert show];
				[alert release];
				
				//if (nil != previousSearchTerm) {
				//	self.searchTerms = previousSearchTerm;
				//	theSearchBar.text = self.searchTerms;
				//}
				
				[self restoreToolBar];
				[theSearchBar becomeFirstResponder];
			}
			else {
				self.lastResults = [[NSMutableDictionary alloc] init];
			}

			
			
		for(NSDictionary * libraryDictionary in result) {
			
			actualCount = [[libraryDictionary objectForKey:@"totalResults"] intValue];
			
			NSString * title = [libraryDictionary objectForKey:@"title"];
			NSString *author = [libraryDictionary objectForKey:@"creator"];
			
			if ([author length] == 0)
				author = @"";
			
			NSString *year = [libraryDictionary objectForKey:@"date"];
			if ([year length] == 0)
				year = @"";
			
			NSString * index = [libraryDictionary objectForKey:@"index"];
			NSString *itemId = [libraryDictionary objectForKey:@"itemId"];
			NSString * edition = [libraryDictionary objectForKey:@"edition"];
			if ([edition length] == 0)
				edition = @"";
			

			NSDictionary * format = [libraryDictionary objectForKey:@"format"];
			
			NSString *typeDetail = [format objectForKey:@"typeDetail"];
			if ([typeDetail length] == 0)
				typeDetail = @"";
			
			NSString * formatDetail = [format objectForKey:@"formatDetail"];
			if ([formatDetail length] == 0)
				formatDetail = @"";
			
			NSString * isOnline = [libraryDictionary objectForKey:@"isOnline"];
			NSString * isFigure = [libraryDictionary objectForKey:@"isFigure"];
			
			BOOL online = NO;
			NSString * onlineLink = @"";
			NSArray * tempA = (NSArray *)[libraryDictionary objectForKey:@"otherAvailability"];
			if ([isOnline isEqualToString:@"YES"]) {
				online = YES;
				
				for(NSDictionary * tempD in tempA) {
					
					NSString * typeOfLink = [tempD objectForKey:@"type"];
					
					if ([typeOfLink isEqualToString:@"NET"])
						onlineLink = [tempD objectForKey:@"link"];
				}
			}
			
			BOOL figure = NO;
			NSString * figureLink = @"";
			if ([isFigure isEqualToString:@"YES"]){
				figure = YES;
				
				for(NSDictionary * tempD1 in tempA) {
					
					NSString * typeOfLink1 = [tempD1 objectForKey:@"type"];
					
					if ([typeOfLink1 isEqualToString:@"FIG"])
						figureLink = [tempD1 objectForKey:@"link"];
				}
				
			}

			
			
			NSPredicate *pred = [NSPredicate predicateWithFormat:@"itemId == %@", itemId];
			LibraryItem *alreadyInDB = [[CoreDataManager objectsForEntity:LibraryItemEntityName matchingPredicate:pred] lastObject];
			
			NSManagedObject *managedObj;
			if (nil == alreadyInDB){
				managedObj = [CoreDataManager insertNewObjectForEntityForName:LibraryItemEntityName];
				alreadyInDB = (LibraryItem *)managedObj;
				alreadyInDB.isBookmarked = [NSNumber numberWithBool:NO];
			}
			alreadyInDB.itemId = itemId;
			alreadyInDB.title = title;
			alreadyInDB.author = author;
			alreadyInDB.year = year;
			alreadyInDB.edition = edition;
			alreadyInDB.typeDetail = typeDetail;
			alreadyInDB.formatDetail = formatDetail;
			alreadyInDB.isFigure = [NSNumber numberWithBool: figure];
			alreadyInDB.isOnline = [NSNumber numberWithBool: online];
			alreadyInDB.onlineLink = onlineLink;
			alreadyInDB.figureLink = figureLink;
			
			
			[CoreDataManager saveData];
			[self.lastResults setObject:alreadyInDB forKey:index];
			}
			[_tableView reloadData];
			
			if ([result count] > 0)
				[_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
		}

	} else if ([result isKindOfClass:[NSDictionary class]]) {

			
			NSString *message = [result objectForKey:@"error"];
            if (message) {
                [self handleWarningMessage:message title:@"Search Failed"];
            }
		/*if (nil != previousSearchTerm) {
			self.searchTerms = previousSearchTerm;
			theSearchBar.text = self.searchTerms;
		}*/
	}
	else {
		self.searchResults = nil;
	}
	
	[searchController hideSearchOverlayAnimated:YES];
}

- (BOOL)request:(JSONAPIRequest *)request shouldDisplayAlertForError:(NSError *)error
{
    return YES;
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error
{
	[self cleanUpConnection];
}


- (void)handleWarningMessage:(NSString *)message title:(NSString *)theTitle {
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:theTitle 
													message:message
												   delegate:self
										  cancelButtonTitle:@"OK" 
										  otherButtonTitles:nil]; 
	[alert show];
	[alert release];
	
	[searchController hideSearchOverlayAnimated:YES];
}



@end
