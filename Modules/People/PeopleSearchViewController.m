#import "PeopleSearchViewController.h"
#import "PersonDetails.h"
#import "PeopleRecentsData.h"
#import "KGOAppDelegate.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "ModoNavigationController.h"
// external modules
#import "Foundation+KGOAdditions.h"
#import "UIKit+KGOAdditions.h"
#import "KGOSearchBar.h"
#import "KGOSearchDisplayController.h"
#import "KGOTheme.h"
#import "ThemeConstants.h"
#import "CoreDataManager.h"

static const NSUInteger kPhoneDirectorySection = 0;

@implementation PeopleSearchViewController

@synthesize searchTerms, searchTokens, searchController;
@synthesize searchBar = theSearchBar;

#pragma mark view

- (void)viewDidLoad {
	[super viewDidLoad];
	
    // TODO: make this come from API
    if (!phoneDirectoryEntries) {
        NSString *filename = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"people/peopleSearchStaticPhoneRowsArray.plist"];
        phoneDirectoryEntries = [[NSArray alloc] initWithContentsOfFile:filename];
    }
    
    //theSearchBar = [[KGOSearchBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, NAVIGATION_BAR_HEIGHT)];
    theSearchBar = [[KGOSearchBar defaultSearchBarWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 44.0)] retain];
	theSearchBar.placeholder = NSLocalizedString(@"Search", nil);

    if (!searchController) {
        searchController = [[KGOSearchDisplayController alloc] initWithSearchBar:self.searchBar delegate:self contentsController:self];
    }
    
	if ([self.searchTerms length] > 0) {
		theSearchBar.text = self.searchTerms;
        [searchController executeSearch:self.searchTerms params:nil];
    }

    [self.view addSubview:theSearchBar];
    CGRect frame = CGRectMake(0.0, theSearchBar.frame.size.height,
                              self.view.frame.size.width,
                              self.view.frame.size.height - theSearchBar.frame.size.height);
	self.tableView = [self addTableViewWithFrame:frame style:UITableViewStyleGrouped];
    
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
    UIView *hintsContainer = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.frame.size.width, labelSize.height + 10.0)] autorelease];
	[hintsContainer addSubview:hintsLabel];
	[hintsLabel release];

	self.tableView.tableHeaderView = hintsContainer;

	// set up screen for when there are no results
	recentlyViewedHeader = nil;
	
	// set up table footer
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setFrame:CGRectMake(10.0, 0.0, self.tableView.frame.size.width - 20.0, 44.0)];
	button.titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
	button.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
	button.titleLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.3];
	[button setTitle:NSLocalizedString(@"Clear Recents", nil) forState:UIControlStateNormal];
	
	// based on code from stackoverflow.com/questions/1427818/iphone-sdk-creating-a-big-red-uibutton
	[button setBackgroundImage:[[UIImage imageNamed:@"people/redbutton2.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0] 
					  forState:UIControlStateNormal];
	[button setBackgroundImage:[[UIImage imageNamed:@"people/redbutton2highlighted.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0] 
					  forState:UIControlStateHighlighted];
	
	[button addTarget:self action:@selector(showActionSheet:) forControlEvents:UIControlEventTouchUpInside];	
	
	UIView *buttonContainer = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.frame.size.width, 44.0)] autorelease];
	[buttonContainer addSubview:button];
	
	self.tableView.tableFooterView = buttonContainer;
	
	if ([[[PeopleRecentsData sharedData] recents] count] == 0) {
		self.tableView.tableFooterView.hidden = YES;
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
    self.tableView.tableFooterView.hidden = ([[[PeopleRecentsData sharedData] recents] count] == 0);

    [[PeopleRecentsData sharedData] loadRecentsFromCache];
	[self reloadDataForTableView:self.tableView];
}

#pragma mark memory

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
	[recentlyViewedHeader release];
	[searchTerms release];
	[searchTokens release];
	[searchController release];
    [phoneDirectoryEntries release];
    [super dealloc];
}

#pragma mark -
#pragma mark Search methods

- (BOOL)searchControllerShouldShowSuggestions:(KGOSearchDisplayController *)controller {
    return YES;
}

- (NSArray *)searchControllerValidModules:(KGOSearchDisplayController *)controller {
    return [NSArray arrayWithObject:PeopleTag];
}

- (NSString *)searchControllerModuleTag:(KGOSearchDisplayController *)controller {
    return PeopleTag;
}

- (void)searchController:(KGOSearchDisplayController *)controller didSelectResult:(id<KGOSearchResult>)aResult {
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:aResult, @"personDetails", nil];
    [(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] showPage:LocalPathPageNameDetail forModuleTag:PeopleTag params:params];
}

- (void)searchController:(KGOSearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView {
    [[CoreDataManager sharedManager] saveData];
    [[PeopleRecentsData sharedData] clearOldResults];
}

#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger numRows = 1;
    if ([[[PeopleRecentsData sharedData] recents] count])
        numRows++;
    return numRows;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: // phone directory
            return phoneDirectoryEntries.count;
        case 1: // recently viewed
            return [[[PeopleRecentsData sharedData] recents] count];
        default:
            return 0;
    }
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *title = nil;
    NSString *detailText = nil;
    NSString *accessoryTag = nil;
    UIColor *backgroundColor = nil;
    
    if (indexPath.section == kPhoneDirectorySection) { // phone directory tel #
        NSDictionary *rowProperties = [phoneDirectoryEntries objectAtIndex:indexPath.row];
        title = [rowProperties objectForKey:@"mainText"];
        detailText = [rowProperties objectForKey:@"secondaryText"];
        accessoryTag = TableViewCellAccessoryPhone;
        backgroundColor = [[KGOTheme sharedTheme] backgroundColorForSecondaryCell];
        
    } else { // recents
        
        PersonDetails *recent = [[[PeopleRecentsData sharedData] recents] objectAtIndex:indexPath.row];
        title = [NSString stringWithFormat:@"%@ %@", 
                 [recent formattedValueForKey:@"givenname"], 
                 [recent formattedValueForKey:@"sn"]];
        
        accessoryTag = KGOAccessoryTypeChevron;
        
        NSArray *displayPriority = [NSArray arrayWithObjects:@"title", @"ou", nil];
        NSString *displayText;
        for (NSString *tag in displayPriority) {
            if (displayText = [recent formattedValueForKey:tag]) {
                detailText = displayText;
                break;
            }
        }
    }
    
    return [[^(UITableViewCell *cell) {
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.text = title;
        cell.detailTextLabel.text = detailText;
        cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:accessoryTag];
        if (backgroundColor) {
            cell.backgroundColor = backgroundColor;
        }
    } copy] autorelease];
}


- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath {
    return KGOTableCellStyleSubtitle;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return NSLocalizedString(@"Recently Viewed", nil);
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (indexPath.section == kPhoneDirectorySection) { 
		NSDictionary *rowProperties = [phoneDirectoryEntries objectAtIndex:indexPath.row];
        NSURL *externURL = [NSURL URLWithString:[rowProperties objectForKey:@"URL"]];
        if ([[UIApplication sharedApplication] canOpenURL:externURL])
            [[UIApplication sharedApplication] openURL:externURL];
		
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

	} else if (indexPath.section == 1) { // recently viewed

		PersonDetails *personDetails = [[[PeopleRecentsData sharedData] recents] objectAtIndex:indexPath.row];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:personDetails, @"personDetails", nil];
        [(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] showPage:LocalPathPageNameDetail forModuleTag:PeopleTag params:params];
	}
}

#pragma mark -
#pragma mark Action sheet methods

- (void)showActionSheet:(id)sender
{
	UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Clear Recents?", nil)
                                                        delegate:self
                                               cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                          destructiveButtonTitle:NSLocalizedString(@"Clear", nil)
                                               otherButtonTitles:nil] autorelease];
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Clear", nil)]) {
		[PeopleRecentsData eraseAll];
		self.tableView.tableFooterView.hidden = YES;
		[self reloadDataForTableView:self.tableView];
		[self.tableView scrollRectToVisible:CGRectMake(0.0, 0.0, 1.0, 1.0) animated:YES];
	}
}

@end

