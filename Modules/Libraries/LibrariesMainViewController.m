//
//  LibrariesMainViewController.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/15/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "LibrariesMainViewController.h"
#import "MITUIConstants.h"
#import "ModoSearchBar.h"
#import "MITSearchDisplayController.h"
#import "MITLoadingActivityView.h"
#import "HoursAndLocationsViewController.h"
#import "LibrariesSearchViewController.h"

@implementation LibrariesMainViewController
@synthesize searchTerms, searchResults, searchController;
@synthesize loadingView;
@synthesize searchBar = theSearchBar, tableView = _tableView;


-(void) setUpLayOut {
	
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
	
    [self.view addSubview:theSearchBar];
	
    CGRect frame = CGRectMake(0.0, theSearchBar.frame.size.height,
                              self.view.frame.size.width,
                              self.view.frame.size.height - theSearchBar.frame.size.height);
	
	_tableView = nil;
	self.tableView = [[[UITableView alloc] initWithFrame:frame style:UITableViewStyleGrouped] autorelease];
	
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
	[self.tableView applyStandardColors];
    
	static NSString *searchHints = @"";
	
	UIFont *hintsFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	CGSize labelSize = [searchHints sizeWithFont:hintsFont
							   constrainedToSize:self.tableView.frame.size
								   lineBreakMode:UILineBreakModeWordWrap];
	
	UILabel *hintsLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 10.0, labelSize.width, labelSize.height + 5.0)];
	hintsLabel.numberOfLines = 0;
	hintsLabel.backgroundColor = [UIColor clearColor];
	hintsLabel.lineBreakMode = UILineBreakModeWordWrap;
	hintsLabel.font = hintsFont;
	hintsLabel.text = searchHints;	
    hintsLabel.textColor = [UIColor colorWithHexString:@"#404040"];
    UIView *hintsContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, labelSize.width, labelSize.height + 10.0)];
	[hintsContainer addSubview:hintsLabel];
	[hintsLabel release];
	
    self.tableView.tableHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 
																			   self.tableView.frame.size.width, 
																			   hintsContainer.frame.size.height)] autorelease];
	[self.tableView.tableHeaderView addSubview:hintsContainer];
	[hintsContainer release];
	
	[self.view addSubview:self.tableView];
    [self.searchBar addDropShadow];
	
	// add our own bookmark button item since we are not using the default
	// bookmark button of the UISearchBar
    // TODO: don't hard code this frame
	
	if (nil == _bookmarkButton) {
		_bookmarkButton = [[UIButton alloc] initWithFrame:CGRectMake(282, 8, 32, 28)];
		[_bookmarkButton setImage:[UIImage imageNamed:@"global/searchfield_star.png"] forState:UIControlStateNormal];
	}
	[self.view addSubview:_bookmarkButton];
	//[_bookmarkButton addTarget:self action:@selector(bookmarkButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
	
	
	// set up tableView options
	
	NSString * option1 = @"Locations and Hours";
	NSString * option2 = @"Find a Place to Study";	
	mainViewTableOptions1 = [[NSArray alloc] initWithObjects: option1, option2, nil];
	
	NSString * option3 = @"Advanced Search";
	NSString * option4 = @"Mobile Research";
	NSString * option5 = @"Questions and Feedback";
	mainViewTableOptions2 = [[NSArray alloc] initWithObjects: option3, option4, option5, nil];
	
	
	hasBookmarkedItems = NO;
	
	if (hasBookmarkedItems == NO) {
		bookmarkedLibraries = [[NSArray alloc] initWithObjects: nil];
		[self hideToolBar];
	}
	else {
		NSString * option6 = @"My Bookmarked Libraries";
		bookmarkedLibraries = [[NSArray alloc] initWithObjects:option6, nil];
	}
	
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setUpLayOut];
	
    
}	

- (void)viewWillAppear:(BOOL)animated
{
	/*for (UIView *view in self.view.subviews) {
		[view removeFromSuperview];
	}*/
	
	//[self setUpLayOut];
	[super viewWillAppear:animated];
	

	[self.tableView reloadData];
}


- (void)viewDidUnload {
    [super viewDidUnload];
	
	searchController = nil;
	theSearchBar = nil;
	
	searchResults = nil;
	
	_tableView = nil;
	
	loadingView = nil;
	api = nil;
	
	// a custom button since we are not using the default bookmark button
	_bookmarkButton = nil;
	
	mainViewTableOptions1 = nil;
	mainViewTableOptions2 = nil;
	
	bookmarkedLibraries = nil;
	
}


- (void)dealloc {
    [super dealloc];

	searchController = nil;
	theSearchBar = nil;
	
	searchResults = nil;
	
	_tableView = nil;
	
	loadingView = nil;
	api = nil;
	
	// a custom button since we are not using the default bookmark button
	_bookmarkButton = nil;
	
	mainViewTableOptions1 = nil;
	mainViewTableOptions2 = nil;
	
	bookmarkedLibraries = nil;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
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


- (void)bookmarkButtonClicked:(UIButton *)sender {
	
	//TODO: open a list-view displaying all bookmarked items
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
    _bookmarkButton.alpha = 0.0;
        theSearchBar.frame = CGRectMake(0, 0, self.view.frame.size.width, NAVIGATION_BAR_HEIGHT);
       // _toolBar.alpha = 0.0;
    [UIView commitAnimations];
}

- (void)restoreToolBar {
    [theSearchBar setShowsCancelButton:NO animated:YES];
    [UIView beginAnimations:@"searching" context:nil];
    [UIView setAnimationDuration:0.4];
	
	if (hasBookmarkedItems)
		_bookmarkButton.alpha = 1.0;

    [UIView commitAnimations];
	
    CGRect frame = _bookmarkButton.frame;
    frame.origin.x = theSearchBar.frame.size.width - frame.size.width - 7;
    _bookmarkButton.frame = frame;
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
	[_bookmarkButton removeFromSuperview];
	
	self.searchTerms = searchBar.text;
	//[self performSearch];
	
	LibrariesSearchViewController *vc = [[LibrariesSearchViewController alloc] initWithViewController: self];
	vc.title = @"Search Results";
	[self.navigationController pushViewController:vc animated:YES];
	[vc release];
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
    self.searchResults = theSearchResults;
    self.searchController.searchResultsTableView.frame = self.tableView.frame;
    [self.view addSubview:self.searchController.searchResultsTableView];
    [self.searchBar addDropShadow];
    [self.searchController.searchResultsTableView reloadData];
}



#pragma mark -
#pragma mark Connection methods

- (void)showLoadingView {
	// manually add loading view because we're not using the built-in data source table
	if (self.loadingView == nil) {
        self.loadingView = [[MITLoadingActivityView alloc] initWithFrame:self.tableView.frame];
	}
	
	[self.tableView addSubview:self.loadingView];
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
			self.searchController.searchResultsTableView.frame = self.tableView.frame;
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



#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0)
		return [mainViewTableOptions1 count] + [bookmarkedLibraries count];
	
	else if (section == 1){
		return [mainViewTableOptions2 count];
	}
	else return 0;

}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	static NSString *optionsForMainViewTableStringConstant = @"InfoCell";
	UITableViewCell *cell = nil;
	

	cell = [tableView dequeueReusableCellWithIdentifier:optionsForMainViewTableStringConstant];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:optionsForMainViewTableStringConstant] autorelease];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
		}
		
		//cell.detailTextLabel.text = @" "; // if this is empty textlabel will be bottom aligned

	int section = indexPath.section;
	int row = indexPath.row;
	
	if (section == 0) {
		if ([bookmarkedLibraries count] > 0) {
			if (row == 0) {
				cell.textLabel.text = (NSString *)[bookmarkedLibraries objectAtIndex:row];
			}
			else {
				cell.textLabel.text = (NSString *)[mainViewTableOptions1 objectAtIndex:row-1];
			}

		}
		else {
			cell.textLabel.text = (NSString *)[mainViewTableOptions1 objectAtIndex:row];
		}
	}
	else if (section == 1) {
		cell.textLabel.text = (NSString *)[mainViewTableOptions2 objectAtIndex:row];
	}
		
	

	return cell;	
}

/*
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{

}
*/

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {

	//return UNGROUPED_SECTION_HEADER_HEIGHT;

	return GROUPED_SECTION_HEADER_HEIGHT;
}

/*

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *titleView = nil;
	

    return titleView;
	
}
 */


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	HoursAndLocationsViewController *vc = [[HoursAndLocationsViewController alloc] init];
	vc.title = @"Locations & Hours";
	[self.navigationController pushViewController:vc animated:YES];
	[vc release];
	

}


@end
