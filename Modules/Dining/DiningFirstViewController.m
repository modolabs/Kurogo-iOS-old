/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import "DiningFirstViewController.h"
#import "MenuDetailsController.h"
#import "MITUIConstants.h"
#import "MIT_MobileAppDelegate.h"
#import "DiningMultiLineCell.h"

#define kBreakfastTab 0
#define kLunchTab 1
#define kDinnerTab 2
#define kHoursTab 3
#define kNewsTab 4

@implementation DiningFirstViewController

@synthesize startingTab = _startingTab;

@synthesize list;
@synthesize _bkfstList;
@synthesize _lunchList;
@synthesize _dinnerList;

@synthesize menuDict;
@synthesize _bkfstDict;
@synthesize _lunchDict;
@synthesize _dinnerDict;

@synthesize todayDate;

@synthesize hoursTableView;
@synthesize tabViews;


NSInteger tabRequestingInfo; // In order to prevent Race conditions for the selected tab and JSONDelegate loaded data
BOOL hoursTabInfoRetrieved = NO;

BOOL requestDispatched = NO;
JSONAPIRequest *mitapi;

-(void)requestBreakfastData
{
	if (requestDispatched == YES)
		[mitapi abortRequest];
	
	[_tabViews removeObjectAtIndex:kBreakfastTab];
	[_tabViews insertObject:_loadingResultView atIndex:kBreakfastTab];
	[_tabViewContainer addSubview:_loadingResultView];
	
	
	
	// Format the requesting URL in the correct Format
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"YYYY-MM-dd"];
	NSString *dateString = [dateFormat stringFromDate:self.todayDate];
	[dateFormat release];
	
	mitapi = [[JSONAPIRequest alloc] initWithJSONAPIDelegate:self];	
	
	
	if ([mitapi requestObjectFromModule:@"dining" 
								command:@"breakfast" 
							 parameters:[NSDictionary dictionaryWithObjectsAndKeys:dateString, @"date", nil]] == YES)
	{
		// set the requesting Tab index to the correct one
		tabRequestingInfo = kBreakfastTab;	
		requestDispatched = YES;
		[self addLoadingIndicator];
	}
	else {
		requestDispatched = NO;
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Failed", nil)
														message:NSLocalizedString(@"Could not connect to server. Please try again later.", nil)
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		
		[alert show];
		[alert release];
	}
	
	
}

-(void)requestLunchData
{
	if (requestDispatched == YES)
		[mitapi abortRequest];
	
	[_tabViews removeObjectAtIndex:kLunchTab];
	[_tabViews insertObject:_loadingResultView atIndex:kLunchTab];
	[_tabViewContainer addSubview:_loadingResultView];
	
	
	// Format the requesting URL in the correct Format
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"YYYY-MM-dd"];
	NSString *dateString = [dateFormat stringFromDate:self.todayDate];
	[dateFormat release];
	
	mitapi = [[JSONAPIRequest alloc] initWithJSONAPIDelegate:self];	
	
	
	if ([mitapi requestObjectFromModule:@"dining" 
								command:@"lunch" 
							 parameters:[NSDictionary dictionaryWithObjectsAndKeys:dateString, @"date", nil]] == YES)
	{
		// set the requesting Tab index to the correct one
		tabRequestingInfo = kLunchTab;	
		requestDispatched = YES;
		[self addLoadingIndicator];
	}
	else {
		requestDispatched = NO;
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Failed", nil)
														message:NSLocalizedString(@"Could not connect to server. Please try again later.", nil)
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		
		[alert show];
		[alert release];
	}
	
	
}

-(void)requestDinnerData
{
	if (requestDispatched == YES)
		[mitapi abortRequest];
	
	[_tabViews removeObjectAtIndex:kDinnerTab];
	[_tabViews insertObject:_loadingResultView atIndex:kDinnerTab];
	[_tabViewContainer addSubview:_loadingResultView];
	
	
	// Format the requesting URL in the correct Format
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"YYYY-MM-dd"];
	NSString *dateString = [dateFormat stringFromDate:self.todayDate];
	[dateFormat release];
	
	mitapi = [[JSONAPIRequest alloc] initWithJSONAPIDelegate:self];	
	if ([mitapi requestObjectFromModule:@"dining" 
								command:@"dinner" 
							 parameters:[NSDictionary dictionaryWithObjectsAndKeys:dateString, @"date", nil]] == YES)
	{
		// set the requesting Tab index to the correct one
		tabRequestingInfo = kDinnerTab;	
		requestDispatched = YES;
		[self addLoadingIndicator];
	}
	else {
		requestDispatched = NO;
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Failed", nil)
														message:NSLocalizedString(@"Could not connect to server. Please try again later.", nil)
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		
		[alert show];
		[alert release];
	}
	
}


-(IBAction)previousButtonPressed
{
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setDay:-1];
    NSDate *next = [gregorian dateByAddingComponents:offsetComponents toDate:self.todayDate options:0];
    [offsetComponents release];
	[gregorian release];
	
	NSDate *minDate = [NSDate dateWithTimeIntervalSinceNow:-7*24*60*60];
	NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:7*24*60*60];
	self.todayDate = next;
	
	if ([next timeIntervalSinceDate:minDate] <= (36*60*60))
		prevDate.enabled = NO;
	
	if ([maxDate timeIntervalSinceDate:next] >= (24*60*60))
		nextDate.enabled = YES;
	
	//[self viewDidLoad];
	
	[self setupDatePicker];
    [self setupTabViews];
    [self setupFirstView];
}

-(IBAction)nextButtonPressed
{
	
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setDay:1];
    NSDate *next = [gregorian dateByAddingComponents:offsetComponents toDate:self.todayDate options:0];
    [offsetComponents release];
	[gregorian release];
	
	NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:7*24*60*60];
	NSDate *minDate = [NSDate dateWithTimeIntervalSinceNow:-7*24*60*60];
	self.todayDate = next;
	
	if ([maxDate timeIntervalSinceDate:next] <= (36*60*60))
		nextDate.enabled = NO;
	
	if ([next timeIntervalSinceDate:minDate] >= (24*60*60))
		prevDate.enabled = YES;
	
	
	//[self viewDidLoad];
    
	[self setupDatePicker];
    [self setupTabViews];
    [self setupFirstView];
}

- (void)setupFirstView {
	
	if (_firstViewDone == NO)
	{
		_firstViewDone = YES;
		
		_tabViewContainer.frame = CGRectMake(_tabViewContainer.frame.origin.x,
                                             _tabViewContainer.frame.origin.y,
                                             _tabViewContainer.frame.size.width,
                                             _tabViewContainerMinHeight);
        
		CGSize contentSize = CGSizeMake(_scrollView.frame.size.width, 
                                        _tabViewContainer.frame.size.height + _tabViewContainer.frame.origin.y);
		
		if (_tabViews == nil)
			_tabViews = [[NSMutableArray alloc] initWithCapacity:4];
        
		[_scrollView setContentSize:contentSize];
        
		[_tabViewControl addTab:@"Breakfast"];	
		[_tabViews insertObject:_loadingResultView atIndex: kBreakfastTab];
        
		[_tabViewControl addTab:@"Lunch"];
		[_tabViews insertObject:_loadingResultView atIndex:kLunchTab];
        
		[_tabViewControl addTab:@"Dinner"];
		[_tabViews insertObject:_loadingResultView atIndex:kDinnerTab];
		
		[_tabViewControl addTab:@"Locations"];
        tableControl = [[HoursTableViewController alloc] init];
		hoursTableView.delegate = (HoursTableViewController *)tableControl;
		hoursTableView.dataSource = (HoursTableViewController *)tableControl;
        
        UILabel *text = [[[UILabel alloc] initWithFrame:CGRectMake(10.0, 60.0, 300.0, 40.0)] autorelease];
        text.text = @"Harvard student ID required. Schedule shown does not account for holidays and other closures.";
        text.font = [UIFont fontWithName:STANDARD_FONT size:12.0];
        text.textColor = [UIColor colorWithHexString:@"#666666"];
        text.lineBreakMode = UILineBreakModeWordWrap;
        text.numberOfLines = 2;
        text.backgroundColor = [UIColor clearColor];
        
        [glossaryForHoursView addSubview:text];
		
		hoursTableView.tableHeaderView =glossaryForHoursView;
		
		tableControl.tableView = hoursTableView;
		
		tableControl.parentViewController = self;
        
		[_tabViews insertObject:_hoursView atIndex:kHoursTab];
		
		_hoursView.backgroundColor = [UIColor whiteColor];
        
		_tabViewControl.hidden = NO;
		_tabViewContainer.hidden = NO;
        
		[_tabViewControl setNeedsDisplay];
		[_tabViewControl setDelegate:self];
        
        
        
        // Open the Default Tab depending on the time of the day
        NSDateFormatter *hourExtractionFormat = [[NSDateFormatter alloc] init];
        [hourExtractionFormat setDateFormat:@"HH"];
        NSString *dateString1 = [hourExtractionFormat stringFromDate:self.todayDate];
        [hourExtractionFormat release];
        
        double doubleHourOfDay = [dateString1 doubleValue];
        
        int tabToOpen = kBreakfastTab;
        
        if (doubleHourOfDay < 9)
        {
            tabToOpen = kBreakfastTab;
            
            [_tabViewControl setSelectedTab:tabToOpen];
            [self requestBreakfastData];
            
        }
        else if (doubleHourOfDay >= 9 && doubleHourOfDay < 14)
        {
            
            
            tabToOpen = kLunchTab;
            [_tabViewControl setSelectedTab:tabToOpen];
            [self requestLunchData];
        }
        
        else if (doubleHourOfDay >=2 && doubleHourOfDay < 24)
        {
            tabToOpen = kDinnerTab;
            [_tabViewControl setSelectedTab:tabToOpen];
            [self requestDinnerData];
            
        }
		
        // set Display Tab
        [self tabControl:_tabViewControl changedToIndex:tabToOpen tabText:nil];
        [_tabViewControl setNeedsDisplay];
	}
	
	else {
		int tab = [_tabViewControl selectedTab];
		
		if (tab == kBreakfastTab)
			[self requestBreakfastData];
		
		else if (tab == kLunchTab)
			[self requestLunchData];
		
		else if (tab == kDinnerTab)
			[self requestDinnerData];
	}
}

- (void)setupTabViews {
	
	if (self.tabViews == nil)
        self.tabViews = [[NSMutableArray alloc] initWithCapacity:5];
	
	// never resize the tab view container below this height. 
	_tabViewContainerMinHeight = _tabViewContainer.frame.size.height;
	
	if (_startingTab) {
		_tabViewControl.selectedTab = _startingTab;
	}
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    _firstViewDone = NO;
	
	[self setupDatePicker];
	
	// Display the Date in the Expected Format: Saturday, June 25
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"EEEE, MMMM d"];
	//NSString *dateString = [dateFormat stringFromDate:self.todayDate];
	[dateFormat release];
    
    [self setupTabViews];
	
	//self.label.text = dateString;
	
    [self setupFirstView];
	
	self.view.backgroundColor = [UIColor clearColor];
	_tabViewContainer.backgroundColor = [UIColor whiteColor];
	
	//[breakfastTable.tableHeaderView  addSubView:glossaryForHoursView];
	//breakfastTable.tableHeaderView = glossaryForMealTypesView;
	///lunchTable.tableHeaderView = glossaryForMealTypesView;
	//dinnerTable.tableHeaderView = glossaryForMealTypesView;
}



- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
    [super viewDidUnload];
	
	self.list = nil;
	self._bkfstList = nil;
	self._lunchList = nil;
	self._dinnerList = nil;
	
	breakfastTable = nil;
	lunchTable = nil;
	dinnerTable = nil;
	
	self.menuDict = nil;
	self._bkfstDict = nil;
	self._lunchList = nil;
	self._dinnerDict = nil;
	
	datePicker = nil;
	childController = nil;
	todayDate = nil;
	
	hoursTableView = nil;
    
    [tableControl release];
	tableControl = nil;
	
	loadingIndicator = nil;
    _firstViewDone = NO;
}


- (void)dealloc {
	[_tabViews release];
	[_tabViewControl release];
	[_tabViewContainer release];
	[lunchViewLink release];
	[_scrollView release];
	[dinnerViewLink release];
	[_loadingResultView release];
	[breakfastViewLink release];
	
	[loadingIndicator release];
	[_noResultsView release];
	
	[list release];
	[_bkfstList release];
	[_lunchList release];
	[_dinnerList release];
	[menuDict release];
	[_bkfstDict release];
	[_lunchDict release];
	[_dinnerDict release];
	
	[datePicker release];
	[breakfastTable release];
	[lunchTable release];
	[dinnerTable release];
	
	[childController release];
	[todayDate release];
	
	[hoursTableView release];
	[tableControl release];
	
    [super dealloc];
}


#pragma mark TabViewControlDelegate
-(void) tabControl:(DiningTabViewControl*)control changedToIndex:(int)tabIndex tabText:(NSString*)tabText
{
	// change the content based on the tab that was selected
	for(UIView* subview in [_tabViewContainer subviews])
	{
		[subview removeFromSuperview];
	}
	
	if (tabIndex == kBreakfastTab)
	{
		[control setSelectedTab:kBreakfastTab];
		[self requestBreakfastData];
		[breakfastTable reloadData];
		lunchTable.tableHeaderView = nil;
		dinnerTable.tableHeaderView = nil;
		/*breakfastTable.tableHeaderView = glossaryForMealTypesView;
		 breakfastTable.tableHeaderView = breakfastTable.tableHeaderView;*/
		
	}	
	else if (tabIndex == kLunchTab)
	{
		[control setSelectedTab:kLunchTab];
		[self requestLunchData];	
		[lunchTable reloadData];
		breakfastTable.tableHeaderView = nil;
		dinnerTable.tableHeaderView = nil;
		/*lunchTable.tableHeaderView = glossaryForMealTypesView;
		 lunchTable.tableHeaderView = lunchTable.tableHeaderView;*/
		
	}	
	
	else if (tabIndex == kDinnerTab)
	{
		[control setSelectedTab:kDinnerTab];
		[self requestDinnerData];
		[dinnerTable reloadData];
		breakfastTable.tableHeaderView = nil;
		lunchTable.tableHeaderView = nil;
		/*dinnerTable.tableHeaderView = glossaryForMealTypesView;
		 dinnerTable.tableHeaderView = dinnerTable.tableHeaderView;*/
		
	}	
	
	else if (tabIndex == kHoursTab)
	{
		[control setSelectedTab:kHoursTab];
		
		if (hoursTabInfoRetrieved == NO) {
			JSONAPIRequest *hoursDelegate = [[[JSONAPIRequest alloc] initWithJSONAPIDelegate:tableControl] autorelease];
			
			if ([hoursDelegate requestObjectFromModule:@"dining" 
											   command:@"hours" 
											parameters:nil] == YES)
			{
				// set the requesting Tab index to the correct one
				tabRequestingInfo = kHoursTab;	
				requestDispatched = YES;
				hoursTabInfoRetrieved = NO;
			}
			
			else {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Failed", nil)
																message:NSLocalizedString(@"Could not connect to server. Please try again later.", nil)
															   delegate:nil
													  cancelButtonTitle:@"OK"
													  otherButtonTitles:nil];
				
				[alert show];
				[alert release];
			}
		}
		else {
			requestDispatched = NO;
			[self removeLoadingIndicator];
		}
	}
	
	// set the size of the scroll view based on the size of the view being added and its parent's offset
	UIView* viewToAdd = [_tabViews objectAtIndex:tabIndex];
	_scrollView.contentSize = CGSizeMake(_scrollView.contentSize.width,
										 _tabViewContainer.frame.origin.y + viewToAdd.frame.size.height);
	
	[_tabViewContainer addSubview:viewToAdd];
	
	if (requestDispatched == YES)
		[self addLoadingIndicator];
	
}

#pragma mark -
#pragma mark DakePicker setup


- (void)setupDatePicker
{
	if (_firstViewDone == NO)
	{
		self.todayDate = [NSDate date];
	}
    
	if (datePicker == nil) {
		
		CGFloat yOffset = 0.0;
		CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
		
		datePicker = [[UIView alloc] initWithFrame:CGRectMake(0.0, yOffset, appFrame.size.width, 44.0)];
		UIImageView *datePickerBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, datePicker.frame.size.width, datePicker.frame.size.height)];
		datePickerBackground.image = [[UIImage imageNamed:@"global/subheadbar_background.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
		[datePicker addSubview:datePickerBackground];
		[datePickerBackground release];
		
        UIButton *showCalendar = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *buttonImage = [UIImage imageNamed:@"global/subheadbar_button"];
        showCalendar.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
        showCalendar.center = CGPointMake(21.0, 21.0);
        [showCalendar setBackgroundImage:buttonImage forState:UIControlStateNormal];
        [showCalendar setBackgroundImage:[UIImage imageNamed:@"global/subheadbar_button_pressed"] forState:UIControlEventTouchUpInside];
        [showCalendar setImage:[UIImage imageNamed:@"global/subheadbar_calendar"] forState:UIControlStateNormal];
        [showCalendar addTarget:self action:@selector(pickDate) forControlEvents:UIControlEventTouchUpInside];
        [datePicker addSubview:showCalendar];
		
		prevDate = [UIButton buttonWithType:UIButtonTypeCustom];
		buttonImage = [UIImage imageNamed:@"global/subheadbar_button_previous"];
		prevDate.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
		prevDate.center = CGPointMake(appFrame.size.width - buttonImage.size.width - 21.0, 21.0);
		[prevDate setBackgroundImage:buttonImage forState:UIControlStateNormal];
		[prevDate setBackgroundImage:[UIImage imageNamed:@"global/subheadbar_button_previous_pressed"] forState:UIControlStateHighlighted];
		//[prevDate setImage:[UIImage imageNamed:MITImageNameLeftArrow] forState:UIControlStateNormal];
		[prevDate addTarget:self action:@selector(previousButtonPressed) forControlEvents:UIControlEventTouchUpInside];
		[datePicker addSubview:prevDate];
		
		nextDate = [UIButton buttonWithType:UIButtonTypeCustom];
        buttonImage = [UIImage imageNamed:@"global/subheadbar_button_next"];
		nextDate.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
		nextDate.center = CGPointMake(appFrame.size.width - 21.0, 21.0);
		[nextDate setBackgroundImage:buttonImage forState:UIControlStateNormal];
		[nextDate setBackgroundImage:[UIImage imageNamed:@"global/subheadbar_button_next_pressed"] forState:UIControlStateHighlighted];
		//[nextDate setImage:[UIImage imageNamed:MITImageNameRightArrow] forState:UIControlStateNormal];
		[nextDate addTarget:self action:@selector(nextButtonPressed) forControlEvents:UIControlEventTouchUpInside];
		[datePicker addSubview:nextDate];
	}
	
	[datePicker removeFromSuperview];
    
    NSInteger randomTag = 3289;
	
	for (UIView *view in [datePicker subviews]) {
		if (view.tag == randomTag) {
			[view removeFromSuperview];
		}
	}
    
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	//[dateFormat setDateFormat:@"YYYY-MM-dd"];
	//[dateFormat setDateFormat:@"EEEE, MMM. d"];
	[dateFormat setDateFormat:@"EEEE M/dd"];
	NSString *dateText = [dateFormat stringFromDate:self.todayDate];
	
	NSString *currentDate = [dateFormat stringFromDate:[NSDate date]];
	[dateFormat release];
	
	if([dateText isEqualToString:currentDate])
		dateText = @"Today";
	
	UIFont *dateFont = [UIFont fontWithName:BOLD_FONT size:20.0];
	CGSize textSize = [dateText sizeWithFont:dateFont];
    
    UIButton *dateButton = [UIButton buttonWithType:UIButtonTypeCustom];
    //dateButton.frame = CGRectMake(0.0, 0.0, textSize.width, textSize.height);
    CGFloat dateButtonWidth = 2 * (prevDate.frame.origin.x - (datePicker.frame.size.width / 2));
    dateButton.frame = CGRectMake(0.0, (datePicker.frame.size.width - dateButtonWidth) / 2, dateButtonWidth, textSize.height);
    dateButton.titleLabel.text = dateText;
    dateButton.titleLabel.font = dateFont;
    dateButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    dateButton.titleLabel.textColor = [UIColor whiteColor];
    [dateButton setTitle:dateText forState:UIControlStateNormal];
    dateButton.center = CGPointMake(datePicker.center.x, datePicker.center.y - datePicker.frame.origin.y);
	//[dateButton addTarget:self action:@selector(pickDate) forControlEvents:UIControlEventTouchUpInside];
    dateButton.tag = randomTag;
    [datePicker addSubview:dateButton];
	
	[self.view addSubview:datePicker];
}

- (void)pickDate {
	
	DatePickerViewController *dateSelector = [[DatePickerViewController alloc] init];
	dateSelector.delegate = self;
	
	
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate presentAppModalViewController:dateSelector animated:YES];
	
	/* Bound the dates to One week in the past and One week in the future */
	NSDate *minDate = [NSDate dateWithTimeIntervalSinceNow:-6*24*60*60];
	dateSelector.datePicker.minimumDate = minDate;
	
	NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:6*24*60*60];
	dateSelector.datePicker.maximumDate = maxDate;
    [dateSelector release];
}

#pragma mark -
#pragma mark Table Data Source Methods


// helper internal method to be called before any displaying
// ensures that the correct list and dict is selected
-(void)correctTableForTabSelected
{
	if(_tabViewControl.selectedTab == kBreakfastTab)
	{
		self.list = self._bkfstList;	
		self.menuDict = self._bkfstDict;
	}
	
	else if(_tabViewControl.selectedTab == kLunchTab)
	{
		self.list = self._lunchList;
		self.menuDict = self._lunchDict;
	}
	
	else if (_tabViewControl.selectedTab == kDinnerTab)
	{
		self.list = self._dinnerList;
		self.menuDict = self._dinnerDict;
	}	
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	[self correctTableForTabSelected];
	return [self.list count];	
}


-(NSInteger)tableView:(UITableView *)tableView
numberOfRowsInSection:(NSInteger)section
{
	
	[self correctTableForTabSelected];
	
	NSString *key = [self.list objectAtIndex:section];
	NSArray *keySection = [self.menuDict objectForKey:key];
	
	return [keySection count];
}


-(UITableViewCell *)tableView:(UITableView *)tableView
		cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self correctTableForTabSelected];
	
	static NSString *CellIdentifier = @"Cell";
		
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];
	
	NSString *key = [self.list objectAtIndex:section];
	NSArray *keySection = [self.menuDict objectForKey:key];
    
	cell.textLabel.text = (NSString *) [[keySection objectAtIndex:row] objectForKey:@"item"];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.backgroundColor = GROUPED_VIEW_CELL_COLOR;
	
	return cell;
}

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	
	//	return [[UIView alloc] initWithFrame: CGRectMake(0, 0, 320.0, UNGROUPED_SECTION_HEADER_HEIGHT)];
	
	
	// create the parent view that will hold header Label
	UIView* customView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, GROUPED_SECTION_HEADER_HEIGHT)] autorelease];
	
	// create the button object
	UILabel * headerLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	headerLabel.backgroundColor = [UIColor clearColor];
	headerLabel.opaque = NO;
	//headerLabel.textColor = [UIColor blackColor];
	//headerLabel.highlightedTextColor = [UIColor whiteColor];
	headerLabel.font = [UIFont fontWithName:BOLD_FONT size:STANDARD_CONTENT_FONT_SIZE];
	headerLabel.textColor= [UIColor colorWithHexString:@"#554c41"];
	headerLabel.frame = CGRectMake(10.0, 0.0, 300.0, GROUPED_SECTION_HEADER_HEIGHT);
	
	[self correctTableForTabSelected];
	NSString *key = [self.list objectAtIndex:section];
	headerLabel.text = key;
	[customView addSubview:headerLabel];
	return customView;
	
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return GROUPED_SECTION_HEADER_HEIGHT;
}

#pragma mark -
#pragma mark Table Delegate Methods

-(void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// deselect the Row
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
	// If details of the Menu-Items are available, uncomment the code below
	/*
	 //re-initialize the childController each time to get the correct Display
	 childController = nil;
	 
	 if (childController == nil)
	 {
	 childController = [[MenuDetailsController alloc] init];
	 }
	 
	 childController.title = @"Disclosure Button Pressed";
	 NSUInteger row = [indexPath row];
	 NSUInteger section = [indexPath section];
	 NSString *key = [self.list objectAtIndex:section];
	 NSArray *keySection = [self.menuDict objectForKey:key];
	 
	 NSString *selectItem = (NSString *)[[keySection objectAtIndex:row] objectForKey:@"item"];
	 NSArray *details;
	 NSArray *categories;
	 
	 
	 NSArray *desc = [(NSDictionary *)[keySection objectAtIndex:row] allValues];
	 NSMutableArray *tempArray = [[NSMutableArray alloc] init];
	 
	 for (int i = 0; i < [desc count]; i++)
	 {
	 NSString *tempStr;		
	 
	 //Check to see if the Category Value is a BOOL or String *
	 BOOL isString = [[desc objectAtIndex:i] isKindOfClass: [NSString class]];
	 
	 if (isString == NO)
	 {
	 if ([[desc objectAtIndex:i] boolValue]== NO)
	 tempStr = @"No";
	 
	 else 
	 {
	 tempStr = @"Yes";
	 }
	 
	 }
	 else
	 tempStr = (NSString *)[[desc objectAtIndex:i] description];
	 
	 [tempArray addObject:tempStr];
	 }
	 details = tempArray;
	 categories = [[keySection objectAtIndex:row] allKeys];
	 
	 
	 [childController setDetails:details setItemCategory: categories];
	 childController.title = selectItem;
	 
	 [self.navigationController pushViewController:childController animated:YES];
	 */
	
	
}

#pragma mark -
#pragma mark JSONLoadedDelegate Method

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)JSONObject;
{
	
	if ([_tabViewControl selectedTab] == tabRequestingInfo)
	{
		// Use the MenuItems class to retrieve Data in the required order/format
		MenuItems *menu = [[MenuItems alloc] init];
		
		// Ensure that the "getData:" method is called before the "getItems and "getMenuDetails" methods
		[menu getData:JSONObject];			
		NSArray *List = [menu getItems];
		NSDictionary *ListDictionary = [menu getMenuDetails];
		
		[menu release];
		
		if ([List count] > 0)
		{		
			// Deal with presenting the Retrieved Data
			for(UIView* subview in [_tabViewContainer subviews])
			{
				[subview removeFromSuperview];
			}
			
			if(_tabViewControl.selectedTab == kBreakfastTab)
			{
				self._bkfstList = List;
				self._bkfstDict = ListDictionary;
				[_tabViews removeObjectAtIndex:kBreakfastTab];
				[_tabViews insertObject:breakfastViewLink atIndex:kBreakfastTab];
				[_tabViewContainer addSubview:breakfastViewLink];
			}
			
			else if(_tabViewControl.selectedTab == kLunchTab)
			{
				self._lunchList = List;
				self._lunchDict = ListDictionary;
				[_tabViews removeObjectAtIndex:kLunchTab];
				[_tabViews insertObject:lunchViewLink atIndex:kLunchTab];
				[_tabViewContainer addSubview:lunchViewLink];
				
			}
			
			else if (_tabViewControl.selectedTab == kDinnerTab)
			{
				self._dinnerList = List;
				self._dinnerDict = ListDictionary;
				[_tabViews removeObjectAtIndex:kDinnerTab];
				[_tabViews insertObject:dinnerViewLink atIndex:kDinnerTab];
				[_tabViewContainer addSubview:dinnerViewLink];
				
			}
			
			[breakfastTable reloadData];
			[lunchTable reloadData];
			[dinnerTable reloadData];
		}
		
		else 
		{
			[_tabViews removeObjectAtIndex:_tabViewControl.selectedTab];
			[_tabViews insertObject:_noResultsView atIndex:_tabViewControl.selectedTab];
			[_tabViewContainer addSubview:_noResultsView];
		}
	}
	[self removeLoadingIndicator];
	requestDispatched = NO;
	
	
}

- (BOOL)request:(JSONAPIRequest *)request shouldDisplayAlertForError:(NSError *)error {
    return YES;
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error {
    [self removeLoadingIndicator];
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
		self.todayDate = nil;
		self.todayDate = [[[NSDate alloc] initWithTimeInterval:0 sinceDate:date] retain];   
		
		MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
		[appDelegate dismissAppModalViewControllerAnimated:YES];
		
		NSDate *minDate = [NSDate dateWithTimeIntervalSinceNow:-7*24*60*60];
		NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:7*24*60*60];
		
		if ([self.todayDate timeIntervalSinceDate:minDate] <= (36*60*60))
			prevDate.enabled = NO;
		
		if ([maxDate timeIntervalSinceDate:self.todayDate] >= (24*60*60))
			nextDate.enabled = YES;
		
		if ([maxDate timeIntervalSinceDate:self.todayDate] <= (36*60*60))
			nextDate.enabled = NO;
		
		if ([self.todayDate timeIntervalSinceDate:minDate] >= (24*60*60))
			prevDate.enabled = YES;
		
		[self setupDatePicker];
		// Display the Date in the Expected Format: Saturday, June 25
		NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
		[dateFormat setDateFormat:@"EEEE, MMMM d"];
		//NSString *dateString = [dateFormat stringFromDate:self.todayDate];
		[dateFormat release];
		
		[self setupTabViews];
		
		//self.label.text = dateString;
		
		[self setupFirstView];
		
		self.view.backgroundColor = [UIColor clearColor];
		_tabViewContainer.backgroundColor = [UIColor whiteColor];
	}
	return;
}
- (void)datePickerValueChanged:(id)sender {
	return;
}

#pragma mark -
#pragma mark LoadingIndicator

- (void)addLoadingIndicator
{
	if (loadingIndicator == nil) {
		static NSString *loadingString = @"Loading...";
		UIFont *loadingFont = [UIFont fontWithName:STANDARD_FONT size:17.0];
		CGSize stringSize = [loadingString sizeWithFont:loadingFont];
		
        CGFloat verticalPadding = 10.0;
        CGFloat horizontalPadding = 16.0;
        CGFloat horizontalSpacing = 3.0;
        //CGFloat cornerRadius = 8.0;
        
        UIActivityIndicatorViewStyle style = UIActivityIndicatorViewStyleGray; // : UIActivityIndicatorViewStyleWhite;
		UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
        spinny.center = CGPointMake(spinny.center.x + horizontalPadding, spinny.center.y + verticalPadding);
		[spinny startAnimating];
        
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(spinny.frame.size.width + horizontalPadding + horizontalSpacing, verticalPadding, stringSize.width, stringSize.height + 2.0)];
		label.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];// : [UIColor whiteColor];
		label.text = loadingString;
		label.font = loadingFont;
		label.backgroundColor = [UIColor clearColor];
        
		loadingIndicator = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, stringSize.width + spinny.frame.size.width + horizontalPadding * 2, stringSize.height + verticalPadding * 2)];
		// loadingIndicator.layer.cornerRadius = cornerRadius;
        loadingIndicator.backgroundColor = [UIColor clearColor]; // : [UIColor colorWithWhite:0.0 alpha:0.8];
		[loadingIndicator addSubview:spinny];
		[spinny release];
		[loadingIndicator addSubview:label];
		[label release];
	}
	
	// self.view.frame changes depending on whether it's the first time we're looking at this,
	// so we need to figure out its position based on things that don't change
	CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
	CGFloat yOffset = 0.0;
	
	if (datePicker != nil)
		yOffset += datePicker.frame.size.height;
	
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

@end
