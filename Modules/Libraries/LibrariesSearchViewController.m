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

@class LibrariesMultiLineCell;

@implementation LibrariesSearchViewController

@synthesize lastResultsTitles;
@synthesize lastResultsOtherDetails;
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
		
		self.lastResultsTitles = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
								@"Freakonomics: A rogue economist explores the hidden economic bj bfdb fbdsfb", @"0",
								@"Freakonomics: A rogue economist explores the hidden economic bj bfdb fbdsfb", @"1",
								@"Freakonomics [sound recording]: A rogue economist explores the hidden economic bj bfdb fbdsfb", @"2",
								  @"From economics", @"3", nil];
		
		self.lastResultsOtherDetails = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
										@"2005 | Levitt, Steven D.", @"0",
										@"2006 | Levitt, Steven D.", @"1",
										@"2006 | Levitt, Steven D.", @"2",
										@"2009 | Fine, Benjamin and Bradford Elgin", @"3", nil];
		
		//_tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
		//_tableView.delegate = self;
		//_tableView.dataSource = self;
		
		//[self.view addSubview:_tableView];
	}
	return self;
}

- (void) dealloc {
	[lastResultsTitles release];
	[lastResultsOtherDetails release];
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
}

#pragma mark UITableViewDataSource methods

- (NSInteger) tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
	return [lastResultsTitles count];
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
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	
	cell.textLabel.text = [NSString stringWithFormat:@"%d. %@", 
						   indexPath.row + 1, [self.lastResultsTitles objectForKey:[NSString stringWithFormat:@"%d", indexPath.row]]];
	cell.detailTextLabel.text = [self.lastResultsOtherDetails objectForKey:[NSString stringWithFormat:@"%d", indexPath.row]];
	cell.detailTextLabel.textColor = [UIColor colorWithHexString:@"#554C41"];
	
	UIImage *image = [UIImage imageNamed:@"dining/dining-status-open.png"];
	cell.imageView.image = image;
	
	
	return cell;
}

- (CGFloat) tableView: (UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath {
	//return [StellarClassTableCell cellHeightForTableView:tableView class:[self.lastResults objectAtIndex:indexPath.row]];
	
	UITableViewCellAccessoryType accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	NSString *cellText = [self.lastResultsTitles objectForKey:[NSString stringWithFormat:@"%d", indexPath.row]];
	NSString *detailText = [self.lastResultsOtherDetails objectForKey:[NSString stringWithFormat:@"%d", indexPath.row]];
	
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
										maxDetailLines:1
												  font:nil 
											detailFont:detailFont
										 accessoryType:accessoryType
											 cellImage:YES];
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *)tableView {
	return 1;
}

- (NSString *) tableView: (UITableView *)tableView titleForHeaderInSection: (NSInteger)section {
	if([lastResultsTitles count]) {
		if (actualCount > [lastResultsTitles count])
			return [NSString stringWithFormat:@"Displaying %i of many", [lastResultsTitles count]];
		
		return [NSString stringWithFormat:@"%i matches found", [lastResultsTitles count]];
	}
	return nil;
}

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString *headerTitle = nil;
	
	if([lastResultsTitles count]) {
		if (actualCount > [lastResultsTitles count])
			headerTitle =  [NSString stringWithFormat:@"Displaying %i of many", [lastResultsTitles count]];
		else
			headerTitle = [NSString stringWithFormat:@"%i matches found", [lastResultsTitles count]];
		
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
	
	NSString * title = @"Freakonomics: a rogue economist explores the hideen side of everything";
	NSString * authorName =  @"Levitt, Steven D";
	NSString * otherDetail1 = @"1st ed.";
	NSString * otherDetail2 = @"New York : William Morron, 2005";
	NSString * otherDetail3 = @"Book: xii, 242p.";
	
	NSDictionary * libraries = [[NSDictionary alloc] initWithObjectsAndKeys:
								@"152 yards away", @"Cabot Science Library",
								@"0.5 miles away", @"Baker Business School", nil];
	
	LibItemDetailViewController *vc = [[LibItemDetailViewController alloc]  initWithStyle:UITableViewStyleGrouped
																					title:title 
																				   author: authorName 
																			 otherDetail1:otherDetail1 
																			 otherDetail2:otherDetail2 
																			 otherDetail3:otherDetail3 
																				libraries:libraries];
	vc.title = @"Item Detail";
	[self.navigationController pushViewController:vc animated:YES];
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
	
	self.searchTerms = searchBar.text;
	//[self performSearch];
	
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
	[self setupSearchController]; // in case we got rid of it from a memory warning
    [self hideToolBar];
}

- (void)performSearch
{
	// save search tokens for drawing table cells
	/*NSMutableArray *tempTokens = [NSMutableArray arrayWithArray:[[self.searchTerms lowercaseString] componentsSeparatedByString:@" "]];
	 [tempTokens sortUsingFunction:strLenSort context:NULL]; // match longer tokens first
	 self.searchTokens = [NSArray arrayWithArray:tempTokens];
	 */
	NSString *temp = self.searchTerms;
	
	temp = [temp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if ([temp length] == 0){
		//[self handleWarningMessage:@"Nothing Found" title:@"Search Failed"];
		return;
	}
	
	api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
	requestWasDispatched = [api requestObjectFromModule:@"people"
                                                command:@"search"
                                             parameters:[NSDictionary dictionaryWithObjectsAndKeys:self.searchTerms, @"q", nil]];
	
    if (requestWasDispatched) {
		//[self showLoadingView];
    } else {
        //[self handleWarningMessage:@"Could not dispatch search" title:@"Search Failed"];
    }
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
        
        if ([result isKindOfClass:[NSDictionary class]]) {
            NSString *message = [result objectForKey:@"error"];
            if (message) {
                [self handleWarningMessage:message title:@"Search Failed"];
            }
        } else if ([result isKindOfClass:[NSArray class]]) {
            self.searchResults = result;
			self.searchController.searchResultsTableView.frame = _tableView.frame;
			[self.view addSubview:self.searchController.searchResultsTableView];
			[self.searchBar addDropShadow];
			
			[self.searchController.searchResultsTableView reloadData];
        }
    }
	else {
		self.searchResults = nil;
	}
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
}



@end
