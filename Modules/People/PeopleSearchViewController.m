#import "PeopleSearchViewController.h"
#import "PersonDetails.h"
#import "PeopleDetailsViewController.h"
#import "PeopleRecentsData.h"
#import "PartialHighlightTableViewCell.h"
#import "MIT_MobileAppDelegate.h"
#import "ConnectionDetector.h"
#import "ModoNavigationController.h"
// common UI elements
#import "MITLoadingActivityView.h"
#import "SecondaryGroupedTableViewCell.h"
#import "MITUIConstants.h"
// external modules
#import "Foundation+MITAdditions.h"
#import "UIKit+MITAdditions.h"
#import "ModoSearchBar.h"
#import "MITSearchDisplayController.h"

static const NSUInteger kPhoneDirectorySection = 0;

// this function puts longer strings first
NSInteger strLenSort(NSString *str1, NSString *str2, void *context)
{
    if ([str1 length] > [str2 length])
        return NSOrderedAscending;
    else if ([str1 length] < [str2 length])
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

#pragma mark Private methods

@interface PeopleSearchViewController (Private)

- (void)handleWarningMessage:(NSString *)message title:(NSString *)theTitle;
+ (NSDictionary *)staticPhoneRowPropertiesForIndexPath:(NSIndexPath *)indexPath;
- (void)showSearchResults;

@end


@implementation PeopleSearchViewController

@synthesize searchTerms, searchTokens, searchResults, searchController;
@synthesize loadingView;
@synthesize searchBar = theSearchBar, tableView = _tableView;

- (void)handleWarningMessage:(NSString *)message title:(NSString *)theTitle {
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:theTitle 
													message:message
												   delegate:self
										  cancelButtonTitle:@"OK" 
										  otherButtonTitles:nil]; 
	[alert show];
	[alert release];
}

+ (NSDictionary *)staticPhoneRowPropertiesForIndexPath:(NSIndexPath *)indexPath {
    
	NSDictionary *properties = nil;
	if (indexPath.section == kPhoneDirectorySection) {		
		NSArray *staticPhoneEntries = 
		[NSArray arrayWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:
										  @"peopleSearchStaticPhoneRowsArray.plist"]];
		if (indexPath.row < staticPhoneEntries.count) {
			properties = [staticPhoneEntries objectAtIndex:indexPath.row];
		}
	}
	return properties;
}

#pragma mark view

- (void)viewDidLoad {
	[super viewDidLoad];
	
    theSearchBar = [[ModoSearchBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, NAVIGATION_BAR_HEIGHT)];

	theSearchBar.tintColor = SEARCH_BAR_TINT_COLOR;
	theSearchBar.placeholder = @"Search";
	if ([self.searchTerms length] > 0)
		theSearchBar.text = self.searchTerms;

    self.searchController = [[[MITSearchDisplayController alloc] initWithSearchBar:theSearchBar contentsController:self] autorelease];
	self.searchController.delegate = self;
	self.searchController.searchResultsDelegate = self;
	self.searchController.searchResultsDataSource = self;

    [self.view addSubview:theSearchBar];
    CGRect frame = CGRectMake(0.0, theSearchBar.frame.size.height,
                              self.view.frame.size.width,
                              self.view.frame.size.height - theSearchBar.frame.size.height);
    self.tableView = [[[UITableView alloc] initWithFrame:frame style:UITableViewStyleGrouped] autorelease];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
	[self.tableView applyStandardColors];
    
    NSString *searchHints = NSLocalizedString(@"Tip: You can search above by a person's first or last name or email address.", nil);

	UIFont *hintsFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	CGSize labelSize = [searchHints sizeWithFont:hintsFont
									constrainedToSize:self.tableView.frame.size
										lineBreakMode:UILineBreakModeWordWrap];
	
	UILabel *hintsLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 5.0, labelSize.width, labelSize.height + 5.0)];
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

	// set up screen for when there are no results
	recentlyViewedHeader = nil;
	
	// set up table footer
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setFrame:CGRectMake(10.0, 0.0, self.tableView.frame.size.width - 20.0, 44.0)];
	button.titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
	button.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
	button.titleLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.3];
	[button setTitle:@"Clear Recents" forState:UIControlStateNormal];
	
	// based on code from stackoverflow.com/questions/1427818/iphone-sdk-creating-a-big-red-uibutton
	[button setBackgroundImage:[[UIImage imageNamed:@"people/redbutton2.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0] 
					  forState:UIControlStateNormal];
	[button setBackgroundImage:[[UIImage imageNamed:@"people/redbutton2highlighted.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0] 
					  forState:UIControlStateHighlighted];
	
	[button addTarget:self action:@selector(showActionSheet) forControlEvents:UIControlEventTouchUpInside];	
	
	UIView *buttonContainer = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.frame.size.width, 44.0)] autorelease];
	[buttonContainer addSubview:button];
	
	self.tableView.tableFooterView = buttonContainer;
	
	if ([[[PeopleRecentsData sharedData] recents] count] == 0) {
		self.tableView.tableFooterView.hidden = YES;
	}
    
    [self.view addSubview:self.tableView];
    [self.searchBar addDropShadow];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
    self.tableView.tableFooterView.hidden = ([[[PeopleRecentsData sharedData] recents] count] == 0);

	[self.tableView reloadData];
}

#pragma mark memory

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
	[recentlyViewedHeader release];
	[searchResults release];
	[searchTerms release];
	[searchTokens release];
	[searchController release];
	[loadingView release];
    [super dealloc];
}

#pragma mark -
#pragma mark Search methods

/*
- (void)prepSearchBar {
	if (!self.searchController.active) {
		[self.searchController setActive:YES];
	}
}
*/
- (void)beginExternalSearch:(NSString *)externalSearchTerms {
	self.searchTerms = externalSearchTerms;
	theSearchBar.text = self.searchTerms;
	
	[self performSearch];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	self.searchResults = nil;
	// if they cancelled while waiting for loading
	if (requestWasDispatched) {
		[api abortRequest];
		[self cleanUpConnection];
	}
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	self.searchTerms = searchBar.text;
	[self performSearch];
}

- (void)performSearch
{
	// save search tokens for drawing table cells
	NSMutableArray *tempTokens = [NSMutableArray arrayWithArray:[[self.searchTerms lowercaseString] componentsSeparatedByString:@" "]];
	[tempTokens sortUsingFunction:strLenSort context:NULL]; // match longer tokens first
	self.searchTokens = [NSArray arrayWithArray:tempTokens];
	
	NSString *temp = self.searchTerms;
	
	temp = [temp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if ([temp length] == 0){
		[self handleWarningMessage:NSLocalizedString(@"Your query returned no matches.", nil) title:NSLocalizedString(@"No Results Found", nil)];
		return;
	}
	
	api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
	requestWasDispatched = [api requestObjectFromModule:@"people"
                                                command:@"search"
                                             parameters:[NSDictionary dictionaryWithObjectsAndKeys:self.searchTerms, @"q", nil]];
	
    if (requestWasDispatched) {
		[self showLoadingView];
    } else {
        [self handleWarningMessage:NSLocalizedString(@"Could not connect to server. Please try again later.", nil) title:NSLocalizedString(@"Connection Failed", nil)];
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
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (tableView == self.searchController.searchResultsTableView)
		return 1;
	else if ([[[PeopleRecentsData sharedData] recents] count] > 0)
		return 2;
	else
		return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (tableView == self.tableView) {
		switch (section) {
			case 0: // phone directory
			{
				NSArray *staticPhoneEntries = 
				[NSArray arrayWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:
												  @"peopleSearchStaticPhoneRowsArray.plist"]];				
				return staticPhoneEntries.count;
			}
				break;
			case 1: // recently viewed
				return [[[PeopleRecentsData sharedData] recents] count];
				break;
			default:
				return 0;
				break;
		}
	} else {
		return [self.searchResults count];
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	static NSString *secondaryCellID = @"InfoCell";
	static NSString *recentCellID = @"RecentCell";
	UITableViewCell *cell = nil;

	if (tableView == self.tableView) { // show phone directory tel #, recents	
	
		if (indexPath.section == kPhoneDirectorySection) {
			
			cell = [tableView dequeueReusableCellWithIdentifier:secondaryCellID];
			if (cell == nil) {
				NSDictionary *rowProperties = [PeopleSearchViewController staticPhoneRowPropertiesForIndexPath:indexPath];
				cell = [[[SecondaryGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:secondaryCellID] autorelease];
				cell.textLabel.text = [rowProperties objectForKey:@"mainText"];
				[(SecondaryGroupedTableViewCell *)cell secondaryTextLabel].text = [rowProperties objectForKey:@"secondaryText"];
				cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
				cell.selectionStyle = UITableViewCellSelectionStyleGray;
			}
		
		} else { // recents
			
			cell = [tableView dequeueReusableCellWithIdentifier:recentCellID];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:recentCellID] autorelease];
				cell.selectionStyle = UITableViewCellSelectionStyleGray;
			}
			
			[cell applyStandardFonts];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

			PersonDetails *recent = [[[PeopleRecentsData sharedData] recents] objectAtIndex:indexPath.row];
			cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", 
                                   [recent formattedValueForKey:@"givenname"], 
                                   [recent formattedValueForKey:@"sn"]];
			
			// show person's title, dept, or email as cell's subtitle text
			cell.detailTextLabel.text = @" "; // put something there so other cells' contents won't get drawn here
			NSArray *displayPriority = [NSArray arrayWithObjects:@"title", @"ou", nil];
			NSString *displayText;
			for (NSString *tag in displayPriority) {
				if (displayText = [recent formattedValueForKey:tag]) {
					cell.detailTextLabel.text = displayText;
					break;
				}
			}
		}
		
	} else { // search results
		
		cell = [tableView dequeueReusableCellWithIdentifier:@"ResultCell"];
		if (cell == nil) {
			cell = [[[PartialHighlightTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ResultCell"] autorelease];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
		}
			
		NSDictionary *searchResult = [self.searchResults objectAtIndex:indexPath.row];
		NSString *fullname = [NSString string];
        NSArray *namesFromJSON = [searchResult objectForKey:@"cn"];
        if ([namesFromJSON count] > 0)
        {
            fullname = [namesFromJSON objectAtIndex:0];
        }
		
		// figure out which field (if any) to display as subtitle
		// display priority: title, dept
		cell.detailTextLabel.text = @" "; // if this is empty textlabel will be bottom aligned
		NSArray *detailAttributeArray = [searchResult objectForKey:@"title"];
		if ([detailAttributeArray count] > 0) {
			cell.detailTextLabel.text = [detailAttributeArray objectAtIndex:0];
		}
		
		// in this section we try to highlight the parts of the results that match the search terms
		// temporarily place "normal[bold] [bold]normal" as textlabel
		// PartialHightlightTableViewCell will change bracketed text to bold text		
		NSString *preformatString = [NSString stringWithString:fullname];
		NSRange boldRange;
		NSInteger tokenIndex = 0; // if this is the first token we don't need to do the [ vs ] comparison
		for (NSString *token in self.searchTokens) {
			boldRange = [[preformatString lowercaseString] rangeOfString:token];
			if (boldRange.location != NSNotFound) {
				// if range is already bracketed don't create another pair inside
				NSString *leftString = [preformatString substringWithRange:NSMakeRange(0, boldRange.location)];
				if ((tokenIndex > 0) && [[leftString componentsSeparatedByString:@"["] count] > [[leftString componentsSeparatedByString:@"]"] count])
						continue;
				
				preformatString = [NSString stringWithFormat:@"%@[%@]%@",
								   leftString,
								   [preformatString substringWithRange:boldRange],
								   [preformatString substringFromIndex:(boldRange.location + boldRange.length)]];
			}
			tokenIndex++;
		}
		
		cell.textLabel.text = preformatString;
	}
	
	cell.isAccessibilityElement = YES;
	cell.accessibilityLabel = cell.textLabel.text;

	return cell;	
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.tableView && indexPath.section == kPhoneDirectorySection) {
		NSDictionary *rowProperties = [PeopleSearchViewController staticPhoneRowPropertiesForIndexPath:indexPath];
		if (rowProperties) {
			return [SecondaryGroupedTableViewCell suggestedHeightForCellWithText:[rowProperties objectForKey:@"mainText"] 
																		mainFont:kSecondaryGroupMainFont
																	  detailText:[rowProperties objectForKey:@"secondaryText"] 
																	  detailFont:kSecondaryGroupDetailFont];
		}
		else {
			return [tableView rowHeight];
		}		
	} else {
		return CELL_TWO_LINE_HEIGHT;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if (section == 1) {
		return GROUPED_SECTION_HEADER_HEIGHT;
	} else if (tableView == self.searchController.searchResultsTableView && [self.searchResults count] > 0) {
		return UNGROUPED_SECTION_HEADER_HEIGHT;
	} else {
		return 0.0;
	}
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *titleView = nil;
	
	if (section == 1) {
		if (recentlyViewedHeader == nil) {
			recentlyViewedHeader = [[UITableView groupedSectionHeaderWithTitle:@"Recently Viewed"] retain];
		}
		titleView = recentlyViewedHeader;
	} else if (tableView == self.searchController.searchResultsTableView) {
		NSUInteger numResults = [self.searchResults count];
		switch (numResults) {
			case 0:
				break;
			case 50:
				titleView = [UITableView ungroupedSectionHeaderWithTitle:@"Many found, showing 50"];
				break;
			default:
				titleView = [UITableView ungroupedSectionHeaderWithTitle:[NSString stringWithFormat:@"%d found", numResults]];
				break;
		}
	}
	
    return titleView;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (tableView == self.searchController.searchResultsTableView || indexPath.section == 1) { // user selected search result or recently viewed

		PersonDetails *personDetails = nil;
		PeopleDetailsViewController *detailView = [[PeopleDetailsViewController alloc] initWithStyle:UITableViewStyleGrouped];
		if (tableView == self.searchController.searchResultsTableView) {
            DLog(@"%@", [self.searchResults description]);
			NSDictionary *selectedResult = [self.searchResults objectAtIndex:indexPath.row];
			personDetails = [PersonDetails retrieveOrCreate:selectedResult];
		} else {
			personDetails = [[[PeopleRecentsData sharedData] recents] objectAtIndex:indexPath.row];
		}
		detailView.personDetails = personDetails;
		[self.navigationController pushViewController:detailView animated:YES];
		[detailView release];
		
	} else if (indexPath.section == kPhoneDirectorySection) { 
		// we are on home screen and user selected phone		
		[self phoneIconTappedAtIndexPath:indexPath];				
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
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
                [self handleWarningMessage:message title:NSLocalizedString(@"Search Failed", nil)];
            }
        } else if ([result isKindOfClass:[NSArray class]]) {
            self.searchResults = result;
            if ([[PeopleRecentsData sharedData] displayFields] != nil) {
                [self showSearchResults];
            } else {
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(showSearchResults)
                                                             name:PeopleDisplayFieldsDidDownloadNotification
                                                           object:[PeopleRecentsData sharedData]];
            }
        }
    }
	else {
		self.searchResults = nil;
	}
}

- (void)showSearchResults {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PeopleDisplayFieldsDidDownloadNotification object:[PeopleRecentsData sharedData]];
    
    self.searchController.searchResultsTableView.frame = self.tableView.frame;
    [self.view addSubview:self.searchController.searchResultsTableView];
    [self.searchBar addDropShadow];
    [self.searchController.searchResultsTableView reloadData];
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
#pragma mark Action sheet methods

- (void)showActionSheet
{
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Clear Recents?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Clear" otherButtonTitles:nil];
    [sheet showInView:self.view];
    [sheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Clear"]) {
		[PeopleRecentsData eraseAll];
		self.tableView.tableFooterView.hidden = YES;
		[self.tableView reloadData];
		[self.tableView scrollRectToVisible:CGRectMake(0.0, 0.0, 1.0, 1.0) animated:YES];
	}
}

#pragma mark Alert view delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{    
    [self.searchController setActive:YES animated:YES];
}

- (void)phoneIconTappedAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == kPhoneDirectorySection)
	{
		NSDictionary *rowProperties = [PeopleSearchViewController staticPhoneRowPropertiesForIndexPath:indexPath];
		if (rowProperties) {			
			NSURL *externURL = [NSURL URLWithString:[rowProperties objectForKey:@"URL"]];
			if ([[UIApplication sharedApplication] canOpenURL:externURL])
				[[UIApplication sharedApplication] openURL:externURL];
		}
	}

}


@end

