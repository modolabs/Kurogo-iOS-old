#import "CalendarEventsViewController.h"
#import "MITUIConstants.h"
#import "CalendarModule.h"
#import "CalendarDetailViewController.h"
#import "CalendarDataManager.h"
#import "CalendarEventMapAnnotation.h"
#import "MITSearchEffects.h"
#import <QuartzCore/QuartzCore.h>
#import "TileServerManager.h"

#define SCROLL_TAB_HORIZONTAL_PADDING 5.0
#define SCROLL_TAB_HORIZONTAL_MARGIN  5.0

@interface CalendarEventsViewController (Private)

- (void)returnToToday;

// helper methods used in loadView
- (UIButton *)setupScrollButtonLeftButton:(BOOL)isLeftButton;

// helper methods used in reloadView
- (BOOL)canShowMap:(CalendarEventListType)listType;
- (void)incrementStartDate:(BOOL)forward;
- (void)showPreviousDate;
- (void)showNextDate;
- (BOOL)shouldShowDatePicker:(CalendarEventListType)listType;
- (void)setupDatePicker;

// search bar animation
- (void)showSearchBar;
- (void)focusSearchBar;
- (void)unfocusSearchBar;
- (void)hideSearchBar;
- (void)releaseSearchBar;
- (void)showSearchOverlay;
- (void)hideSearchOverlay;
- (void)releaseSearchOverlay;

- (void)addLoadingIndicatorForSearch:(BOOL)isSearch;
- (void)removeLoadingIndicator;

- (void)showSearchResultsMapView;
- (void)showSearchResultsTableView;

@end


@implementation CalendarEventsViewController

@synthesize startDate, endDate, events;
@synthesize activeEventList, showList, showScroller;
@synthesize tableView = theTableView, mapView = theMapView, catID = theCatID;
//@synthesize dateSelector;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		startDate = [[NSDate date] retain];
		endDate = [[NSDate date] retain];
		
		// these two properties should be set by the creator
		// defaults are here for safety
		activeEventList = CalendarEventListTypeEvents;
		showScroller = YES;
		theCatID = kCalendarTopLevelCategoryID;
    }
    return self;
}

- (void)dealloc {
	
	[events release];
	[startDate release];
	[endDate release];
	
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
	if (showList) {
		[theMapView release];
		theMapView = nil;
	} else {
		[theTableView release];
		theTableView = nil;
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	apiRequest = [JSONAPIRequest requestWithJSONAPIDelegate:self];
	
	// sending in the request for Categories List from the server
	if (categoriesRequestDispatched == NO)
		categoriesRequestDispatched = [apiRequest requestObjectFromModule:@"calendar"
																   command:@"categories"
																parameters:nil];
	
	//moved the following commented out code to the request:jsonLoaded function
	
	self.view.backgroundColor = [UIColor clearColor];
	
	if (showScroller) {
		[self.view addSubview:navScrollView];
		[self.view addSubview:rightScrollButton];
		[self.view addSubview:leftScrollButton];
		[self.view addSubview:theSearchBar];
	}
	
	if ([self shouldShowDatePicker:activeEventList]) {
		[self.view addSubview:datePicker];
	}
	
	if (categoriesRequestDispatched) {
		[self addLoadingIndicatorForSearch:NO];
	}
	/*
	[self reloadView:activeEventList];
	 */
}

- (void)viewDidUnload {
	
	[theTableView release];
	[theMapView release];
	[searchResultsTableView release];
	[leftScrollButton release];
	[rightScrollButton release];
	[navScrollView release];
	[datePicker release];
}

#pragma mark View controller

- (void)loadView
{
	[super loadView];
	
	theTableView = nil;
	theMapView = nil;
	searchResultsTableView = nil;
	searchResultsMapView = nil;
	datePicker = nil;
	dateRangeDidChange = YES;
	requestDispatched = NO;
	loadingIndicator = nil;
	
	// TODO: clean up the code to remvoe the types: Exhibits, Academic and Holiday
	//CalendarEventListType buttonTypes[NumberOfCalendarEventListTypes] = {
	CalendarEventListType buttonTypes[3] = {
		CalendarEventListTypeEvents,
		//CalendarEventListTypeExhibits,
		CalendarEventListTypeCategory,
		CalendarEventListTypeAcademic,
		//CalendarEventListTypeHoliday
	};
	
	CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
	
	if (showScroller) {
		
		// lots of copy/paste from StoryListViewController in this section
		
		UIImage *backgroundImage = [UIImage imageNamed:MITImageNameScrollTabBackgroundOpaque];
		UIImage *buttonImage = [UIImage imageNamed:MITImageNameScrollTabSelectedTab];
		UIImage *stretchableButtonImage = [buttonImage stretchableImageWithLeftCapWidth:15 topCapHeight:0];
		
		UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
		UIImage *searchImage = [UIImage imageNamed:MITImageNameSearch];
		[searchButton setImage:searchImage forState:UIControlStateNormal];
		searchButton.tag = 7947; // random number that won't conflict with event list types
	
		// we want the search image to line up exactly with the gray magnifying glass in the search bar
		// but there's no good way to determine the gray image's real position, so these pixel numbers
		// are produced by eyeballing and hoping the position is similar in sdk versions other than 3.0
		searchButton.frame = CGRectMake(10.0,
										9.0,
										searchImage.size.width,
										searchImage.size.height); 
		[searchButton addTarget:self action:@selector(showSearchBar) forControlEvents:UIControlEventTouchUpInside];
		searchButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 1.0, 0);

        UIControl *searchTapRegion = [[UIControl alloc] initWithFrame:CGRectMake(0.0, 0.0, 44.0, 44.0)];
        searchTapRegion.backgroundColor = [UIColor clearColor];
        searchTapRegion.center = searchButton.center;
        [searchTapRegion addTarget:self action:@selector(showSearchBar) forControlEvents:UIControlEventTouchUpInside];
		
		// create buttons for nav scroller view		
		//navButtons = [[NSMutableArray alloc] initWithCapacity:NumberOfCalendarEventListTypes];
		navButtons = [[NSMutableArray alloc] initWithCapacity:NumberOfCalendarEventListTypes];
		
		CGRect buttonFrame = CGRectZero;
		CGFloat leftOffset = searchButton.frame.size.width + 20.0;
		buttonFrame.origin.y = floor((backgroundImage.size.height - buttonImage.size.height) / 2);
		
		for (int i = 0; i < NumberOfCalendarEventListTypes; i++) {

			CalendarEventListType listType = buttonTypes[i];
			NSString *buttonTitle = [CalendarConstants titleForEventType:listType];
			UIButton *aButton = [UIButton buttonWithType:UIButtonTypeCustom];
			aButton.tag = listType;
			[aButton setBackgroundImage:nil forState:UIControlStateNormal];
			[aButton setBackgroundImage:stretchableButtonImage forState:UIControlStateHighlighted];            
			[aButton setTitle:buttonTitle forState:UIControlStateNormal];
			[aButton setTitleColor:[UIColor colorWithHexString:@"#FCCFCF"] forState:UIControlStateNormal];
			[aButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
			aButton.titleLabel.font = [UIFont boldSystemFontOfSize:13.0];
			[aButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
			
			aButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 1.0, 0); // needed to center text vertically within button
			
			CGSize newSize = [aButton.titleLabel.text sizeWithFont:aButton.titleLabel.font];			
			newSize.width += SCROLL_TAB_HORIZONTAL_PADDING * 2 + SCROLL_TAB_HORIZONTAL_MARGIN;
			newSize.height = stretchableButtonImage.size.height;
			
			buttonFrame.size = newSize;
			buttonFrame.origin.x = leftOffset;
			aButton.frame = buttonFrame;
			
			[navButtons addObject:aButton];
			leftOffset += buttonFrame.size.width;
		}
		
		UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, leftOffset, backgroundImage.size.height)];
		[contentView addSubview:searchButton];
		for (UIButton *aButton in navButtons) {
			[contentView addSubview:aButton];
		}
		
		// make Home button active by default
		UIButton *homeButton = [navButtons objectAtIndex:0];
		[homeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[homeButton setBackgroundImage:stretchableButtonImage forState:UIControlStateNormal];
		
		// now that the buttons have all been added, update the content frame
		CGRect newFrame = contentView.frame;
		newFrame.size.width = leftOffset + SCROLL_TAB_HORIZONTAL_PADDING;
		contentView.frame = newFrame;
		
		// Create nav scroll view and add it to the hierarchy
		navScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, appFrame.size.width, backgroundImage.size.height)];
		navScrollView.delegate = self;
		navScrollView.scrollsToTop = NO; // otherwise this competes with the story list for status bar taps
		navScrollView.contentSize = contentView.frame.size;
		navScrollView.showsHorizontalScrollIndicator = NO;
		navScrollView.opaque = NO;
		
		[navScrollView setBackgroundColor:[UIColor colorWithPatternImage:backgroundImage]];
		
		[navScrollView addSubview:contentView];
        [navScrollView addSubview:searchTapRegion];
		[navScrollView addSubview:searchButton];
		[contentView release];
		
		// Prep left and right scrollers
		//leftScrollButton = [[self setupScrollButtonLeftButton:YES] retain];
		//rightScrollButton = [[self setupScrollButtonLeftButton:NO] retain];
	}
	
}



- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// since we add our tableviews manually we also need to do this manually
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
	[searchResultsTableView deselectRowAtIndexPath:[searchResultsTableView indexPathForSelectedRow] animated:YES];
}

- (NSArray *)events
{
	return events;
}

- (void)setEvents:(NSArray *)someEvents
{
	[events release];
	
	events = [someEvents retain];

	theMapView.events = someEvents;
	((EventListTableView *)self.tableView).events = someEvents;
	self.tableView.separatorColor = TABLE_SEPARATOR_COLOR;
}

- (void)returnToTodayAndReload {
    [self returnToToday];
    [self reloadView:activeEventList];
}

- (void)returnToToday {
    [startDate release];
    startDate = [[NSDate date] retain];
    dateRangeDidChange = YES;
}


- (void)pickDate {
	
	DatePickerViewController *dateSelector = [[DatePickerViewController alloc] init];
	dateSelector.delegate = self;
	
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate presentAppModalViewController:dateSelector animated:YES];
    [dateSelector release];
	
}
#pragma mark Redrawing logic and helper functions

- (void)reloadView:(CalendarEventListType)listType {
	
	[self abortExtraneousRequest];
	[searchResultsMapView removeFromSuperview];
	[searchResultsTableView removeFromSuperview];
    [self.tableView removeFromSuperview];
    
	BOOL requestNeeded = YES;
	
	if (listType != activeEventList) {
		activeEventList = listType;
        [self returnToToday];
	}

	CGFloat yOffset = showScroller ? navScrollView.frame.size.height : 0.0;
	if ([self shouldShowDatePicker:activeEventList]) {
		[self setupDatePicker];
		yOffset += datePicker.frame.size.height - 4.0; // 4.0 is height of transparent shadow under image
	} else {
		[datePicker removeFromSuperview];
	}
	
	CGRect contentFrame = CGRectMake(0, self.view.bounds.origin.y + yOffset, 
									 self.view.bounds.size.width, 
									 self.view.bounds.size.height - yOffset);
	
	// see if we need a mapview
	if (![self canShowMap:activeEventList]) {
		showList = YES;
	} else if (self.mapView == nil) {
		self.mapView = [[CalendarMapView alloc] initWithFrame:contentFrame];
		self.mapView.delegate = self;
        //[TileServerManager registerMapView:self.mapView];
	}

	if (dateRangeDidChange && activeEventList != CalendarEventListTypeCategory) {
		requestNeeded = YES;
	}
	
	if (showScroller) {
		self.navigationItem.title = @"Events";
	}
	
	if (showList) {
		
		[self.tableView release];
		self.tableView = nil;
		
		if (activeEventList == CalendarEventListTypeCategory) {
			self.tableView = [[EventCategoriesTableView alloc] initWithFrame:contentFrame style:UITableViewStyleGrouped];			
			[self.tableView applyStandardColors];
			EventCategoriesTableView *categoriesTV = (EventCategoriesTableView *)self.tableView;
			categoriesTV.delegate = categoriesTV;
			categoriesTV.dataSource = categoriesTV;
			categoriesTV.parentViewController = self;

			// populate (sub)categories from core data
			// if we receive nil from core data, then make a trip to the server
			NSArray *categories = nil;
			if (theCatID != kCalendarTopLevelCategoryID) {
				EventCategory *category = [CalendarDataManager categoryWithID:theCatID];
				NSMutableArray *subCategories = [[[category.subCategories allObjects] mutableCopy] autorelease];
				// sort "All" category, i.e. the category that is a subcategory of itself, to the beginning
				[subCategories removeObject:category];
				categories = [[NSArray arrayWithObject:category] arrayByAddingObjectsFromArray:subCategories];
			} else {
				categories = [CalendarDataManager topLevelCategories];
			}
			
			if (categories == nil) {
				requestNeeded = YES;
			} else if (requestNeeded == NO){
				categoriesTV.categories = categories;
			}
			
		} else {
			self.tableView = [[EventListTableView alloc] initWithFrame:contentFrame];
			self.tableView.delegate = (EventListTableView *)self.tableView;
			self.tableView.dataSource = (EventListTableView *)self.tableView;
			((EventListTableView *)self.tableView).parentViewController = self;
			NSArray *someEvents = [CalendarDataManager eventsWithStartDate:startDate
                                                                  listType:activeEventList
																  category:(theCatID == kCalendarTopLevelCategoryID) ? nil : [NSNumber numberWithInt:theCatID]];
			
			if (someEvents != nil && [someEvents count] && (requestNeeded == NO)) {
				self.events = someEvents;
				((EventListTableView *)self.tableView).events = self.events;
				theMapView.events = self.events;
                self.tableView.separatorColor = TABLE_SEPARATOR_COLOR;
				[self.tableView reloadData];
                requestNeeded = NO;
			} else {
				self.tableView.separatorColor = [UIColor whiteColor];
			}
		}
		
		self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
				
		[self.view addSubview:self.tableView];
		
		self.navigationItem.rightBarButtonItem = [self canShowMap:activeEventList]
		? [[[UIBarButtonItem alloc] initWithTitle:@"Map"
											style:UIBarButtonItemStylePlain
										   target:self
										   action:@selector(mapButtonToggled)] autorelease]
		: nil;
		
		[self.mapView removeFromSuperview];
		
	} else {
		
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"List"
																				   style:UIBarButtonItemStylePlain
																				  target:self
																				  action:@selector(listButtonToggled)] autorelease];
		
        [self.view addSubview:self.mapView];
	}
	
	if ([self shouldShowDatePicker:activeEventList]) {
		[self setupDatePicker];
	}
	
	
	requestNeeded = YES;
	
	if (requestNeeded) {
		[self makeRequest];
	}
	
	dateRangeDidChange = NO;
}

- (UIButton *)setupScrollButtonLeftButton:(BOOL)isLeftButton
{
	UIImage *scrollImage = [UIImage imageNamed:(isLeftButton) ? MITImageNameScrollTabLeftEndCap : MITImageNameScrollTabRightEndCap];
	UIButton *scrollButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[scrollButton setImage:scrollImage forState:UIControlStateNormal];
	CGFloat leftOffset = (isLeftButton) ? 0.0 : [[UIScreen mainScreen] applicationFrame].size.width - scrollImage.size.width;
	CGRect imageFrame = CGRectMake(leftOffset,0.0,scrollImage.size.width,scrollImage.size.height);
	scrollButton.frame = imageFrame;
	scrollButton.hidden = isLeftButton;
	[scrollButton addTarget:self action:@selector(sideButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	return scrollButton;
}

- (void)selectScrollerButton:(NSString *)buttonTitle
{
	for (UIButton *aButton in navButtons) {
		if ([aButton.titleLabel.text isEqualToString:buttonTitle]) {			
			[self buttonPressed:aButton];
			break;
		}
	}
}

- (void)incrementStartDate:(BOOL)forward
{
	NSTimeInterval interval = [CalendarConstants intervalForEventType:activeEventList
															 fromDate:startDate
															  forward:forward];
	@synchronized(self) {
		NSDate *otherDate = startDate;
		startDate = nil;
		startDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:otherDate];
		[otherDate release];
	}
    
	dateRangeDidChange = YES;
	[self reloadView:activeEventList];
}

- (void)showPreviousDate {
	[self incrementStartDate:NO];
}

- (void)showNextDate {
	[self incrementStartDate:YES];
}

- (BOOL)canShowMap:(CalendarEventListType)listType {
	return (listType == CalendarEventListTypeEvents || listType == CalendarEventListTypeExhibits);
}

- (BOOL)shouldShowDatePicker:(CalendarEventListType)listType {
	// TODO: refine date picker criteria
	// ideally we would find a better source for holiday info
	// and activate prev/next for holiday view
	return (listType != CalendarEventListTypeCategory && listType != CalendarEventListTypeHoliday);
}

- (void)setupDatePicker
{
	if (datePicker == nil) {
		
		CGFloat yOffset = showScroller ? navScrollView.frame.size.height : 0.0;
		CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
		
		datePicker = [[UIView alloc] initWithFrame:CGRectMake(0.0, yOffset, appFrame.size.width, 44.0)];
		UIImageView *datePickerBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, datePicker.frame.size.width, datePicker.frame.size.height)];
		datePickerBackground.image = [[UIImage imageNamed:@"global/subheadbar_background.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
		[datePicker addSubview:datePickerBackground];
		[datePickerBackground release];
		
		UIImage *buttonImage = [UIImage imageNamed:@"global/subheadbar_button.png"];
		
		UIButton *prevDate = [UIButton buttonWithType:UIButtonTypeCustom];
		prevDate.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
		prevDate.center = CGPointMake(21.0, 21.0);
		[prevDate setBackgroundImage:buttonImage forState:UIControlStateNormal];
		[prevDate setBackgroundImage:[UIImage imageNamed:@"global/subheadbar_button_pressed"] forState:UIControlStateHighlighted];
		[prevDate setImage:[UIImage imageNamed:MITImageNameLeftArrow] forState:UIControlStateNormal];	
		[prevDate addTarget:self action:@selector(showPreviousDate) forControlEvents:UIControlEventTouchUpInside];
		[datePicker addSubview:prevDate];
		
		UIButton *nextDate = [UIButton buttonWithType:UIButtonTypeCustom];
		nextDate.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
		nextDate.center = CGPointMake(appFrame.size.width - 21.0, 21.0);
		[nextDate setBackgroundImage:buttonImage forState:UIControlStateNormal];
		[nextDate setBackgroundImage:[UIImage imageNamed:@"global/subheadbar_button_pressed"] forState:UIControlStateHighlighted];
		[nextDate setImage:[UIImage imageNamed:MITImageNameRightArrow] forState:UIControlStateNormal];
		[nextDate addTarget:self action:@selector(showNextDate) forControlEvents:UIControlEventTouchUpInside];
		[datePicker addSubview:nextDate];		
	}
	
	[datePicker removeFromSuperview];
    
    NSInteger randomTag = 3289;
	
	for (UIView *view in [datePicker subviews]) {
		if (view.tag == randomTag) {
			[view removeFromSuperview];
		}
	}
    
	NSString *dateText = [CalendarConstants dateStringForEventType:activeEventList forDate:startDate];
	UIFont *dateFont = [UIFont fontWithName:BOLD_FONT size:20.0];
	CGSize textSize = [dateText sizeWithFont:dateFont];

    UIButton *dateButton = [UIButton buttonWithType:UIButtonTypeCustom];
    dateButton.frame = CGRectMake(0.0, 0.0, textSize.width, textSize.height);
    dateButton.titleLabel.text = dateText;
    dateButton.titleLabel.font = dateFont;
    dateButton.titleLabel.textColor = [UIColor whiteColor];
    [dateButton setTitle:dateText forState:UIControlStateNormal];
    dateButton.center = CGPointMake(datePicker.center.x, datePicker.center.y - datePicker.frame.origin.y);
    //if (![dateText isEqualToString:@"Today"]) {
       // [dateButton addTarget:self action:@selector(returnToTodayAndReload) forControlEvents:UIControlEventTouchUpInside];
		[dateButton addTarget:self action:@selector(pickDate) forControlEvents:UIControlEventTouchUpInside];
    //}
    dateButton.tag = randomTag;
    [datePicker addSubview:dateButton];
	
	[self.view addSubview:datePicker];
}


#pragma mark -
#pragma mark Search bar activation

- (void)showSearchBar
{
    if (!theSearchBar) {
        theSearchBar = [[UISearchBar alloc] initWithFrame:navScrollView.frame];
        theSearchBar.tintColor = SEARCH_BAR_TINT_COLOR;
        theSearchBar.delegate = self;
        theSearchBar.alpha = 0.0;
        [self.view addSubview:theSearchBar];
    }
    
	if (searchResultsTableView == nil) {
		searchResultsTableView = [[EventListTableView alloc] initWithFrame:CGRectMake(0.0, theSearchBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - theSearchBar.frame.size.height)];
		searchResultsTableView.parentViewController = self;
		searchResultsTableView.delegate = searchResultsTableView;
		searchResultsTableView.dataSource = searchResultsTableView;
	}
	
	if (searchResultsMapView == nil) {
		searchResultsMapView = [[CalendarMapView alloc] initWithFrame:CGRectMake(0.0, theSearchBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - theSearchBar.frame.size.height)];
        searchResultsMapView.region = self.mapView.region;
		searchResultsMapView.delegate = self;
	}
    
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.4];
	theSearchBar.alpha = 1.0;
	[UIView commitAnimations];
	[self focusSearchBar];
}

- (void)focusSearchBar {
    
	// focus the search field, bring in the cancel button
	[theSearchBar setShowsCancelButton:YES animated:YES];
	[theSearchBar becomeFirstResponder];
    
	// put a dim overlay on the table
	[self showSearchOverlay];
}

- (void)unfocusSearchBar {
	if (theSearchBar) {
		[theSearchBar resignFirstResponder];
		[theSearchBar setShowsCancelButton:NO animated:YES];
	}
}

- (void)hideSearchBar {
	if (theSearchBar) {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.4];
        [UIView setAnimationDidStopSelector:@selector(releaseSearchBar)];
		theSearchBar.alpha = 0.0;
		[UIView commitAnimations];
	}
}

- (void)releaseSearchBar {
    [theSearchBar removeFromSuperview];
    [theSearchBar release];
}

- (void)showSearchOverlay {
	if (!searchOverlay) {
		searchOverlay = [[MITSearchEffects alloc] initWithFrame:CGRectMake(0.0, theSearchBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - theSearchBar.frame.size.height)];
		searchOverlay.controller = self;
		searchOverlay.alpha = 0.0;
		[self.view addSubview:searchOverlay];
	}
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.4];
	searchOverlay.alpha = 1.0;
	[UIView commitAnimations];
}

- (void)hideSearchOverlay {
	if (searchOverlay) {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.4];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(releaseSearchOverlay)];
		searchOverlay.alpha = 0.0;
		[UIView commitAnimations];
	}
}

- (void)releaseSearchOverlay {
    [searchOverlay removeFromSuperview];
    [searchOverlay release];
    searchOverlay = nil;
}

- (void)searchOverlayTapped
{
	if (searchResultsTableView.events != nil) {
		[self unfocusSearchBar];
		[self hideSearchOverlay];
	} else {
		[self searchBarCancelButtonClicked:theSearchBar];
	}
}

#pragma mark Search delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[self makeSearchRequest:searchBar.text];
    [self unfocusSearchBar];

}

// required if user initiates a new search when results are up
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
	[self focusSearchBar];
	[self showSearchOverlay];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	if (![searchOverlay isDescendantOfView:self.view]) {
		[self.view addSubview:searchOverlay];
	}
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{	
	[self abortExtraneousRequest];

	theSearchBar.text = [NSString string];
	[self unfocusSearchBar];
	[self hideSearchBar];
	[self hideSearchOverlay];
    
	[searchResultsTableView removeFromSuperview];
	[searchResultsMapView removeFromSuperview];
	[self reloadView:activeEventList];
}

#pragma mark -

- (void)showSearchResultsMapView {
	showList = NO;
	[self.view addSubview:searchResultsMapView];
	[searchResultsTableView removeFromSuperview];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"List"
																			   style:UIBarButtonItemStylePlain
																			  target:self
																			  action:@selector(showSearchResultsTableView)] autorelease];
}

- (void)showSearchResultsTableView {
	showList = YES;
	[self.view addSubview:searchResultsTableView];
	[searchResultsMapView removeFromSuperview];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Map"
																			   style:UIBarButtonItemStylePlain
																			  target:self
																			  action:@selector(showSearchResultsMapView)] autorelease];
}

#pragma mark -
#pragma mark UI Event observing

- (void)mapButtonToggled {
	showList = NO;
	[self reloadView:activeEventList];
}

- (void)listButtonToggled {
	showList = YES;
	[self reloadView:activeEventList];
}


- (void)sideButtonPressed:(id)sender {
    // see comment in News/StoryListViewController.m
    CGPoint offset = navScrollView.contentOffset;
	CGRect tabRect = CGRectMake(0, 0, 1, 1);
    
    if (sender == leftScrollButton) {
        NSInteger i, count = [navButtons count];
        for (i = count - 1; i >= 0; i--) {
            UIButton *tab = [navButtons objectAtIndex:i];
            if (CGRectGetMinX(tab.frame) - offset.x < 0) {
                tabRect = tab.frame;
                tabRect.origin.x -= leftScrollButton.frame.size.width - 8.0;
                break;
            }
        }
    } else if (sender == rightScrollButton) {
        for (UIButton *tab in navButtons) {
            if (CGRectGetMaxX(tab.frame) - (offset.x + navScrollView.frame.size.width) > 0) {
                tabRect = tab.frame;
                tabRect.origin.x += rightScrollButton.frame.size.width - 8.0;
                break;
            }
        }
    }
	[navScrollView scrollRectToVisible:tabRect animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if ([scrollView isEqual:navScrollView]) {
		CGPoint offset = scrollView.contentOffset;
		if (offset.x <= 0) {
			leftScrollButton.hidden = YES;
		} else {
			leftScrollButton.hidden = NO;
		}
		if (offset.x >= navScrollView.contentSize.width - navScrollView.frame.size.width) {
			rightScrollButton.hidden = YES;
		} else {
			rightScrollButton.hidden = NO;
		}
	}
}

- (void)buttonPressed:(id)sender {
    UIButton *pressedButton = (UIButton *)sender;
	
    NSMutableArray *buttons = [navButtons mutableCopy];
	
    if ([buttons containsObject:pressedButton]) {
        [buttons removeObject:pressedButton];
        
        UIImage *buttonImage = [UIImage imageNamed:MITImageNameScrollTabSelectedTab];
        UIImage *stretchableButtonImage = [buttonImage stretchableImageWithLeftCapWidth:15 topCapHeight:0];
        
        [pressedButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [pressedButton setBackgroundImage:stretchableButtonImage forState:UIControlStateNormal];
        
        for (UIButton *aButton in buttons) {
            [aButton setTitleColor:[UIColor colorWithHexString:@"#FCCFCF"] forState:UIControlStateNormal];
            [aButton setBackgroundImage:nil forState:UIControlStateNormal];
        }
        
		[self reloadView:pressedButton.tag];
    }
    
    [buttons release];
}

- (void)addLoadingIndicatorForSearch:(BOOL)isSearch
{
	if (loadingIndicator == nil) {
		static NSString *loadingString = @"Loading...";
		UIFont *loadingFont = [UIFont fontWithName:STANDARD_FONT size:17.0];
		CGSize stringSize = [loadingString sizeWithFont:loadingFont];

        CGFloat verticalPadding = 10.0;
        CGFloat horizontalPadding = 16.0;
        CGFloat horizontalSpacing = 3.0;
        CGFloat cornerRadius = 8.0;
        
        UIActivityIndicatorViewStyle style = (showList) ? UIActivityIndicatorViewStyleGray : UIActivityIndicatorViewStyleWhite;
		UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
        spinny.center = CGPointMake(spinny.center.x + horizontalPadding, spinny.center.y + verticalPadding);
		[spinny startAnimating];
        
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(spinny.frame.size.width + horizontalPadding + horizontalSpacing, verticalPadding, stringSize.width, stringSize.height + 2.0)];
		label.textColor = (showList) ? [UIColor colorWithWhite:0.5 alpha:1.0] : [UIColor whiteColor];
		label.text = loadingString;
		label.font = loadingFont;
		label.backgroundColor = [UIColor clearColor];
        
		loadingIndicator = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, stringSize.width + spinny.frame.size.width + horizontalPadding * 2, stringSize.height + verticalPadding * 2)];
        loadingIndicator.layer.cornerRadius = cornerRadius;
        loadingIndicator.backgroundColor = (showList) ? [UIColor clearColor] : [UIColor colorWithWhite:0.0 alpha:0.8];
		[loadingIndicator addSubview:spinny];
		[spinny release];
		[loadingIndicator addSubview:label];
		[label release];

		//loadingIndicator.backgroundColor = label.backgroundColor;
	}

	// self.view.frame changes depending on whether it's the first time we're looking at this,
	// so we need to figure out its position based on things that don't change
	CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
	CGFloat yOffset = showScroller ? navScrollView.frame.size.height : 0.0;
	if (!isSearch && [self shouldShowDatePicker:activeEventList]) {
		yOffset += datePicker.frame.size.height;
	}
	//MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	//CGFloat heightAdjustment = appDelegate.tabBarController.tabBar.frame.size.height;
    CGFloat heightAdjustment = 0;
	CGPoint center = CGPointMake(appFrame.size.width / 2, (appFrame.size.height + yOffset) / 2 - heightAdjustment);
	loadingIndicator.center = center;
	
	[self.view addSubview:loadingIndicator];
}

- (void)removeLoadingIndicator
{
	[loadingIndicator removeFromSuperview];
    [loadingIndicator release];
    loadingIndicator = nil;
}

#pragma mark Map View Delegate
 
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
	CalendarEventMapAnnotation *annotation = view.annotation;
	MITCalendarEvent *event = nil;
	CalendarMapView *calMapView = (CalendarMapView *)mapView;
	for (event in calMapView.events) {
		if (event.eventID == annotation.event.eventID) {
			break;
		}
	}

	if (event != nil) {
		CalendarDetailViewController *detailVC = [[CalendarDetailViewController alloc] init];
		detailVC.event = event;
		[self.navigationController pushViewController:detailVC animated:YES];
		[detailVC release];
	}
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	MKPinAnnotationView *annotationView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"adsf"] autorelease];
    annotationView.animatesDrop = YES;
    annotationView.canShowCallout = YES;
    UIButton *disclosureButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    annotationView.rightCalloutAccessoryView = disclosureButton;
	
	//MKAnnotationView *annotationView = [mapView viewForAnnotation:annotation];
    
	return annotationView;
}

#pragma mark Server connection methods

- (void)abortExtraneousRequest
{
	if (requestDispatched) {
		[apiRequest abortRequest];
		[self removeLoadingIndicator];
		requestDispatched = NO;
	}
}

- (void)makeSearchRequest:(NSString *)searchTerms
{
	[self abortExtraneousRequest];

	apiRequest = [JSONAPIRequest requestWithJSONAPIDelegate:self];
	apiRequest.userData = CalendarEventAPISearch;
	requestDispatched = [apiRequest requestObjectFromModule:CalendarTag 
												   command:@"search" 
												parameters:[NSDictionary dictionaryWithObjectsAndKeys:searchTerms, @"q", nil]];

	if (requestDispatched) {
		if (showList) {
			searchResultsTableView.events = nil;
			searchResultsTableView.separatorColor = [UIColor whiteColor];
            searchResultsTableView.isSearchResults = NO;
			[searchResultsTableView reloadData];
			[self showSearchResultsTableView];
		} else {
			searchResultsMapView.events = nil;
			[self showSearchResultsMapView];
		}
		
		[self addLoadingIndicatorForSearch:YES];
	}
}

- (void)makeRequest
{
	[self abortExtraneousRequest];
	
	apiRequest = [JSONAPIRequest requestWithJSONAPIDelegate:self];
	apiRequest.userData = [CalendarConstants titleForEventType:activeEventList];
	
	switch (activeEventList) {
		case CalendarEventListTypeEvents:
			if (theCatID != kCalendarTopLevelCategoryID) {
				NSTimeInterval interval = [startDate timeIntervalSince1970];
				NSString *timeString = [NSString stringWithFormat:@"%d", (int)interval];
				requestDispatched = [apiRequest requestObjectFromModule:CalendarTag
																command:@"category"
															 parameters:[NSDictionary dictionaryWithObjectsAndKeys:
																		 [NSString stringWithFormat:@"%d", theCatID], @"id",
																		 timeString, @"start", nil]];
				break;
			}
			// fall through
		case CalendarEventListTypeExhibits:
		{
			// TODO: add other time ranges
			NSTimeInterval interval = [startDate timeIntervalSince1970];
			NSString *timeString = [NSString stringWithFormat:@"%d", (int)interval];
			
			requestDispatched = [apiRequest requestObjectFromModule:CalendarTag
															command:[CalendarConstants apiCommandForEventType:activeEventList]
														 parameters:[NSDictionary dictionaryWithObjectsAndKeys:
																	 [CalendarConstants titleForEventType:activeEventList], @"type", 
																	 timeString, @"time", nil]];
			break;
		}
		case CalendarEventListTypeAcademic:
		{
			NSCalendar *calendar = [NSCalendar currentCalendar];
			NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit;
			NSDateComponents *comps = [calendar components:unitFlags fromDate:startDate];
			NSString *month = [NSString stringWithFormat:@"%d", [comps month]];
			NSString *year = [NSString stringWithFormat:@"%d", [comps year]];

			requestDispatched = [apiRequest requestObjectFromModule:CalendarTag
															command:[CalendarConstants apiCommandForEventType:activeEventList]
														 parameters:[NSDictionary dictionaryWithObjectsAndKeys:year, @"year", month, @"month", nil]];
			break;
		}
		default:
			requestDispatched = [apiRequest requestObjectFromModule:CalendarTag
															command:[CalendarConstants apiCommandForEventType:activeEventList]
														 parameters:nil];
			break;
	}
	
	if (requestDispatched) {
		[self addLoadingIndicatorForSearch:NO];
	}
}

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result {
	
	[self removeLoadingIndicator];

	// moved the following from viewDidLoad to ensure that the categories request completed before a load view
	 if (categoriesRequestDispatched == YES)
	 {
		 NSMutableArray *arrayForTable = [NSMutableArray arrayWithCapacity:[result count]];
			 
		 
			 for (NSDictionary *catDict in result) {
				 EventCategory *category = [CalendarDataManager categoryWithDict:catDict];
				 [arrayForTable addObject:category];
			 }
			 ((EventCategoriesTableView *)self.tableView).categories = [NSArray arrayWithArray:arrayForTable];
		 
		 self.view.backgroundColor = [UIColor clearColor];
		 /*
		 if (showScroller) {
			 [self.view addSubview:navScrollView];
			 [self.view addSubview:rightScrollButton];
			 [self.view addSubview:leftScrollButton];
			 [self.view addSubview:theSearchBar];
		 }*/
	 
		 if ([self shouldShowDatePicker:activeEventList]) {
			 [self.view addSubview:datePicker];
		 }
	 
		 [self reloadView:activeEventList];
	 
		 categoriesRequestDispatched = NO;
	 }	
	
	requestDispatched = NO;

	if (![request.userData isEqualToString:CalendarEventAPISearch]
		&& ![request.userData isEqualToString:[CalendarConstants titleForEventType:activeEventList]]) {
		//NSLog(@"received result for request %@", request.userData);
		return; // we are no longer interested in this result
	}
    
    if (result && [request.userData isEqualToString:CalendarEventAPISearch] && [result isKindOfClass:[NSDictionary class]]) {
		
		BOOL resultEventsExist = NO;
        NSArray *resultEvents = [result objectForKey:@"events"];
		NSString *resultSpan;
		NSMutableArray *arrayForTable;
		
		if (![resultEvents isKindOfClass:[NSNull class]]) {
			
			resultEventsExist = YES;
			resultSpan = [result objectForKey:@"span"];
			arrayForTable = [NSMutableArray arrayWithCapacity:[resultEvents count]];
		
			for (NSDictionary *eventDict in resultEvents) {
				MITCalendarEvent *event = [CalendarDataManager eventWithDict:eventDict];
				[arrayForTable addObject:event];
			}
        }
		
		if ((resultEventsExist == YES) && ([resultEvents count] > 0)) {
            
			NSArray *eventsArray = [NSArray arrayWithArray:arrayForTable];
			searchResultsMapView.events = eventsArray;
			searchResultsTableView.events = eventsArray;
			searchResultsTableView.separatorColor = TABLE_SEPARATOR_COLOR;		
			searchResultsTableView.searchSpan = resultSpan;
			searchResultsTableView.isSearchResults = YES;
			[self hideSearchOverlay];
			[searchResultsTableView reloadData];
            
			if (showList) {
				[self showSearchResultsTableView];
			} else {
				[self showSearchResultsMapView];
			}
            
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Nothing found" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
            [alertView release];
            [self releaseSearchOverlay];
        }
        
    } else if (result && [result isKindOfClass:[NSArray class]]) {
		
		NSMutableArray *arrayForTable = [NSMutableArray arrayWithCapacity:[result count]];
		
		if (activeEventList == CalendarEventListTypeCategory) {

			for (NSDictionary *catDict in result) {
				EventCategory *category = [CalendarDataManager categoryWithDict:catDict];
				[arrayForTable addObject:category];
			}
			((EventCategoriesTableView *)self.tableView).categories = [NSArray arrayWithArray:arrayForTable];
		
		} else {
            // academic & holiday events have no category so we assign something to differentiate them
            EventCategory *category = nil;
            switch (activeEventList) {
                case CalendarEventListTypeAcademic:
                    category = [CalendarDataManager categoryWithID:kCalendarAcademicCategoryID];
                    break;
                case CalendarEventListTypeHoliday:
                    category = [CalendarDataManager categoryWithID:kCalendarHolidayCategoryID];
                    break;
                case CalendarEventListTypeExhibits:
                    category = [CalendarDataManager categoryWithID:kCalendarExhibitCategoryID];
                    break;
                default:
                    if (theCatID != kCalendarTopLevelCategoryID) {
                        category = [CalendarDataManager categoryWithID:theCatID];
                    }
                    break;
            }
            
			if (([result count] == 0) && ([self.navigationItem.rightBarButtonItem.title isEqualToString:@"Map"])){
				UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 300, 20)];
																		   
				label.text = @"No Events Found";															   
				NSInteger vertical_margin = 45;
				
				if (theCatID == -1)
					vertical_margin += 50;
				
				CGRect contentFrame = CGRectMake(0,self.view.bounds.origin.y + vertical_margin, 
												 self.view.bounds.size.width, 
												 self.view.bounds.size.height);
				
				nothingFound = [[UIView alloc] initWithFrame:contentFrame];
				[nothingFound setBackgroundColor:[UIColor whiteColor]];
				
				[nothingFound addSubview:label];
				[self.view addSubview:nothingFound];
			}
			else if (nothingFound != nil) {
				[nothingFound removeFromSuperview];
			}
			
			if (([result count] == 0) && (activeEventList == CalendarEventListTypeAcademic)) {
				UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 300, 20)];
				
				label.text = @"No Events this month";															   
				NSInteger vertical_margin = 45;
				
				if (theCatID == -1)
					vertical_margin += 50;
				
				CGRect contentFrame = CGRectMake(0,self.view.bounds.origin.y + vertical_margin, 
												 self.view.bounds.size.width, 
												 self.view.bounds.size.height);
				
				nothingFound = [[UIView alloc] initWithFrame:contentFrame];
				[nothingFound setBackgroundColor:[UIColor whiteColor]];
				
				[nothingFound addSubview:label];
				[self.view addSubview:nothingFound];
			}
			
			for (NSDictionary *eventDict in result) {
				MITCalendarEvent *event = [CalendarDataManager eventWithDict:eventDict];
                // assign a category if we know already what it is
                if (category != nil) {
                    [event addCategory:category];
                }
				[arrayForTable addObject:event];
			}
			
			self.events = [NSArray arrayWithArray:arrayForTable];			
		}
		
		if (showList) {
            self.tableView.separatorColor = TABLE_SEPARATOR_COLOR;
			[self.tableView reloadData];
		}
	}
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
	[self focusSearchBar];
}

- (void)handleConnectionFailureForRequest:(JSONAPIRequest *)request
{
	requestDispatched = NO;
    [self removeLoadingIndicator];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Failed"
                                                    message:@"Could not retrieve events from server"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];

    [alert show];
    [alert release];
}


#pragma mark -
#pragma mark DatePickerViewControllerDelegate functions

- (void)datePickerViewControllerDidCancel:(DatePickerViewController *)controller {
	
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate dismissAppModalViewControllerAnimated:YES];
	
	return;
}

- (void)datePickerViewController:(DatePickerViewController *)controller didSelectDate:(NSDate *)date {
	
	if ([controller class] == [DatePickerViewController class]) {
		startDate = nil;
		startDate = [[NSDate alloc] initWithTimeInterval:0 sinceDate:date];    
		dateRangeDidChange = YES;

		MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
		[appDelegate dismissAppModalViewControllerAnimated:YES];
		
		[self reloadView:activeEventList];
	}
	return;
}
- (void)datePickerValueChanged:(id)sender {
	return;
}

@end









