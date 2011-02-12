#import "CalendarEventsViewController.h"
#import "MITUIConstants.h"
#import "CalendarModule.h"
#import "CalendarDetailViewController.h"
#import "CalendarDataManager.h"
#import "KGOSearchDisplayController.h"
#import <QuartzCore/QuartzCore.h>
#import "TileServerManager.h"
#import "KGOSearchBar.h"

#define SCROLL_TAB_HORIZONTAL_PADDING 5.0
#define SCROLL_TAB_HORIZONTAL_MARGIN  5.0
#define SEARCH_BUTTON_TAG 7947

@interface CalendarEventsViewController (Private)

- (void)returnToToday;

// helper methods used in reloadView
- (void)incrementStartDate:(BOOL)forward;
- (void)showPreviousDate;
- (void)showNextDate;
- (BOOL)shouldShowDatePicker:(CalendarEventListType)listType;
- (void)setupDatePicker;

// search bar animation
- (void)showSearchBar;
- (void)hideSearchBar;
- (void)releaseSearchBar;

- (void)addLoadingIndicatorForSearch:(BOOL)isSearch;
- (void)removeLoadingIndicator;

@end


@implementation CalendarEventsViewController

@synthesize startDate, endDate, events;
@synthesize activeEventList, showScroller, categoriesRequestDispatched;
@synthesize catID = theCatID;
@synthesize searchTerms;
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
    }
    return self;
}
*/
- (void)dealloc {
	
	[navScrollView release];
	[datePicker release];
	[events release];
	[startDate release];
	[endDate release];
	[loadingIndicator release];
	[nothingFound release];
	
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	if (showScroller) {
        [self.view addSubview:navScrollView];
    }
    
    if ([self shouldShowDatePicker:activeEventList]) {
        [self.view addSubview:datePicker];
    }
	
	apiRequest = [[JSONAPIRequest requestWithJSONAPIDelegate:self] retain];
	
	// sending in the request for Categories List from the server
	if (categoriesRequestDispatched == NO) {
        apiRequest.userData = [NSString stringWithString:@"categories"];
		categoriesRequestDispatched = [apiRequest requestObjectFromModule:@"calendar"
                                                                  command:@"categories"
                                                               parameters:nil];
    } else {
		[self reloadView:activeEventList];
	}

	if (categoriesRequestDispatched) {
		[self addLoadingIndicatorForSearch:NO];
	}
}

- (void)viewDidUnload {
	
	[navScrollView release];
	[datePicker release];
	[loadingIndicator release];
	[nothingFound release];
}

#pragma mark View controller

- (void)loadView
{
	[super loadView];
    startDate = [[NSDate date] retain];
    endDate = [[NSDate date] retain];
    
    // these two properties should be set by the creator
    // defaults are here for safety
    activeEventList = CalendarEventListTypeEvents;
    showScroller = YES;
    theCatID = kCalendarTopLevelCategoryID;
	
	datePicker = nil;
	dateRangeDidChange = YES;
	requestDispatched = NO;
	loadingIndicator = nil;
	
	// TODO: get this from server
	CalendarEventListType buttonTypes[3] = {
		CalendarEventListTypeEvents,
		CalendarEventListTypeCategory,
		CalendarEventListTypeAcademic,
	};
	
	CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
	
	if (showScroller) {
        if (!navScrollView) {
            navScrollView = [[KGOScrollingTabstrip alloc] initWithFrame:CGRectMake(0, 0, appFrame.size.width, 44.0)];
            navScrollView.delegate = self;
            navScrollView.showsSearchButton = YES;
        }

		// create buttons for nav scroller view		
		for (int i = 0; i < NumberOfCalendarEventListTypes; i++) {

			CalendarEventListType listType = buttonTypes[i];
			NSString *buttonTitle = [CalendarConstants titleForEventType:listType];
            [navScrollView addButtonWithTitle:buttonTitle];
		}
        
        [navScrollView setNeedsLayout];
        
        // highlight active category
        // TODO: use active category instead of always start at first tab
        NSString *buttonTitle = [CalendarConstants titleForEventType:0];
        for (NSInteger i = 0; i < navScrollView.numberOfButtons; i++) {
            if ([[navScrollView buttonTitleAtIndex:i] isEqualToString:buttonTitle]) {
                [navScrollView selectButtonAtIndex:i];
                break;
            }
        }
	}
	
}



- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// since we add our tableviews manually we also need to do this manually
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)returnToTodayAndReload {
    [self returnToToday];
    [self reloadView:activeEventList];
}

- (void)returnToToday {
    [startDate release];
    startDate = [[NSDate date] retain];
    
    datePicker.date = startDate;
    
    dateRangeDidChange = YES;
}

#pragma mark Redrawing logic and helper functions

- (void)reloadView:(CalendarEventListType)listType {
    
	[self abortExtraneousRequest];
    
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
	
	if (dateRangeDidChange && activeEventList != CalendarEventListTypeCategory) {
		requestNeeded = YES;
	}
	
	if (showScroller) {
		self.navigationItem.title = @"Events";
	}
		
			if (nothingFound != nil) {
				[nothingFound removeFromSuperview];
			}
		
		if (activeEventList == CalendarEventListTypeCategory) {
			if (nothingFound != nil) {
				[nothingFound removeFromSuperview];
			}

			// populate (sub)categories from core data
			// if we receive nil from core data, then make a trip to the server
            [categories release];
			if (theCatID != kCalendarTopLevelCategoryID) {
				EventCategory *category = [CalendarDataManager categoryWithID:theCatID];
				NSMutableArray *subCategories = [[[category.subCategories allObjects] mutableCopy] autorelease];
				// sort "All" category, i.e. the category that is a subcategory of itself, to the beginning
				[subCategories removeObject:category];
				categories = [[NSArray arrayWithObject:category] arrayByAddingObjectsFromArray:subCategories];
			} else {
				categories = [CalendarDataManager topLevelCategories];
			}
			
            [categories retain];
			if (categories == nil) {
				requestNeeded = YES;
			}
			
            if (!_eventCategoriesTableView) {
                _eventCategoriesTableView = [[UITableView alloc] initWithFrame:contentFrame style:UITableViewStyleGrouped];
                [self addTableView:_eventCategoriesTableView];
            }
		} else {
			NSArray *someEvents = [CalendarDataManager eventsWithStartDate:startDate
                                                                  listType:activeEventList
																  category:(theCatID == kCalendarTopLevelCategoryID) ? nil : [NSNumber numberWithInt:theCatID]];
			
			
            if (!_eventListTableView) {
                _eventListTableView = [[UITableView alloc] initWithFrame:contentFrame style:UITableViewStylePlain];
                [self addTableView:_eventListTableView];
            }
            
			if ([someEvents count]) {
				self.events = someEvents;
                [self reloadDataForTableView:_eventListTableView];
                requestNeeded = NO;
			} else {
				requestNeeded = YES;
			}
		}
	
	if ([self shouldShowDatePicker:activeEventList]) {
		[self setupDatePicker];
	}
	
	if (requestNeeded) {
		[self makeRequest];
	}
	
    NSLog(@"reloadview: %@", [_eventListTableView description]);
    NSLog(@"reloadview: %@", [_eventListTableView.dataSource description]);
    NSLog(@"reloadview: %@", [_eventListTableView.delegate description]);
    
	dateRangeDidChange = NO;
}

- (BOOL)shouldShowDatePicker:(CalendarEventListType)listType {
	// TODO: refine date picker criteria
	// ideally we would find a better source for holiday info
	// and activate prev/next for holiday view
	return (listType != CalendarEventListTypeCategory && listType != CalendarEventListTypeHoliday);
}

- (void)setupDatePicker
{
    if (!datePicker) {
		CGFloat yOffset = showScroller ? navScrollView.frame.size.height : 0.0;
		CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
        CGRect frame = CGRectMake(0.0, yOffset, appFrame.size.width, 44.0);
        datePicker = [[KGODatePager alloc] initWithFrame:frame];
        datePicker.delegate = self;
        datePicker.date = startDate;
        datePicker.incrementUnit = NSDayCalendarUnit;
    }
    
	[self.view addSubview:datePicker];
}


#pragma mark -
#pragma mark Search bar activation

- (void)tabstrip:(KGOScrollingTabstrip *)tabstrip clickedButtonAtIndex:(NSUInteger)index {
    if (index == [tabstrip searchButtonIndex]) {
        [self showSearchBar];
    } else {
        CalendarEventListType buttonTypes[3] = {
            CalendarEventListTypeEvents,
            CalendarEventListTypeCategory,
            CalendarEventListTypeAcademic,
        };

        NSString *title = [tabstrip buttonTitleAtIndex:index];
		for (int i = 0; i < NumberOfCalendarEventListTypes; i++) {
			CalendarEventListType listType = buttonTypes[i];
			NSString *buttonTitle = [CalendarConstants titleForEventType:listType];
            if ([buttonTitle isEqualToString:title]) {
                [self reloadView:i];
            }
		}
    }
}

- (void)showSearchBar
{
    if (!theSearchBar) {
        theSearchBar = [[KGOSearchBar defaultSearchBarWithFrame:navScrollView.frame] retain]; //[[KGOSearchBar alloc] initWithFrame:navScrollView.frame];
        theSearchBar.alpha = 0.0;
        if (!searchController) {
            searchController = [[KGOSearchDisplayController alloc] initWithSearchBar:theSearchBar delegate:self contentsController:self];
        }
        [self.view addSubview:theSearchBar];
    }
    [self.view bringSubviewToFront:theSearchBar];
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.4];
	theSearchBar.alpha = 1.0;
	[UIView commitAnimations];
    [searchController setActive:YES animated:YES];
    
    self.navigationItem.rightBarButtonItem = nil;
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
    theSearchBar = nil;
    [searchController release];
    searchController = nil;
}

#pragma mark Search methods

- (BOOL)searchControllerShouldShowSuggestions:(KGOSearchDisplayController *)controller {
    return YES;
}

- (NSArray *)searchControllerValidModules:(KGOSearchDisplayController *)controller {
    return [NSArray arrayWithObject:CalendarTag];
}

- (NSString *)searchControllerModuleTag:(KGOSearchDisplayController *)controller {
    return CalendarTag;
}

- (void)searchController:(KGOSearchDisplayController *)controller didSelectResult:(id<KGOSearchResult>)aResult {

}

- (void)searchController:(KGOSearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView {
    [self hideSearchBar];
}

#pragma mark -
#pragma mark UI Event observing

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
        
		UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		spinny.center = CGPointMake(spinny.center.x + horizontalPadding, spinny.center.y + verticalPadding);
		[spinny startAnimating];
        
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(spinny.frame.size.width + horizontalPadding + horizontalSpacing, verticalPadding, stringSize.width, stringSize.height + 2.0)];
		label.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
		label.text = loadingString;
		label.font = loadingFont;
		label.backgroundColor = [UIColor clearColor];
        
		loadingIndicator = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, stringSize.width + spinny.frame.size.width + horizontalPadding * 2, stringSize.height + verticalPadding * 2)];
        loadingIndicator.layer.cornerRadius = cornerRadius;
        loadingIndicator.backgroundColor = [UIColor clearColor];
		[loadingIndicator addSubview:spinny];
		[spinny release];
		[loadingIndicator addSubview:label];
		[label release];
	}

	CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
	CGPoint center = CGPointMake(appFrame.size.width / 2, (appFrame.size.height) / 2);
	loadingIndicator.center = center;
	
	[self.view addSubview:loadingIndicator];
}

- (void)removeLoadingIndicator
{
	[loadingIndicator removeFromSuperview];
    [loadingIndicator release];
    loadingIndicator = nil;
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
	// if (categoriesRequestDispatched == YES)
    if ([request.userData isEqualToString:@"categories"])
    {
		 NSMutableArray *arrayForTable = [NSMutableArray arrayWithCapacity:[result count]];
		 
			 for (NSDictionary *catDict in result) {
				 EventCategory *category = [CalendarDataManager categoryWithDict:catDict];
				 [arrayForTable addObject:category];
			 }
		 
		 self.view.backgroundColor = [UIColor clearColor];	 
		 [self reloadView:activeEventList];
	 
		 categoriesRequestDispatched = YES;
        return;
	 }	
	
	requestDispatched = NO;

	if (![request.userData isEqualToString:[CalendarConstants titleForEventType:activeEventList]]) {
		//NSLog(@"received result for request %@", request.userData);
		return; // we are no longer interested in this result
	}
    
    if (result && [result isKindOfClass:[NSArray class]]) {
		
		NSMutableArray *arrayForTable = [NSMutableArray arrayWithCapacity:[result count]];
		
		if (activeEventList == CalendarEventListTypeCategory) {

			for (NSDictionary *catDict in result) {
				EventCategory *category = [CalendarDataManager categoryWithDict:catDict];
				[arrayForTable addObject:category];
			}
            [categories release];
            categories = [arrayForTable retain];
		
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
            
			if ([result count] == 0){
				UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(100, 125, 300, 20)];
				label.font = [UIFont systemFontOfSize:17];
																		   
				label.text = @"No Events Found";															   
				NSInteger vertical_margin = 45;
				
				if (theCatID == -1)
					vertical_margin += 50;
				
				CGRect contentFrame = CGRectMake(0,self.view.bounds.origin.y + vertical_margin, 
												 self.view.bounds.size.width, 
												 self.view.bounds.size.height);
				

				nothingFound = nil;
				
				if (nothingFound == nil)
					nothingFound = [[UIView alloc] initWithFrame:contentFrame];
				
				[nothingFound setBackgroundColor:[UIColor whiteColor]];
				
				[nothingFound addSubview:label];
                [label release];
				[self.view addSubview:nothingFound];
               // [nothingFound release];
			}
			else if (nothingFound != nil) {
				[nothingFound removeFromSuperview];
			}
			
			if (([result count] == 0) && (activeEventList == CalendarEventListTypeAcademic)) {
				UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(25, 125, 300, 20)];
				label.font = [UIFont systemFontOfSize:17];
				
				label.text = @"No events for this Academic Year";															   
				NSInteger vertical_margin = 45;
				
				if (theCatID == -1)
					vertical_margin += 50;
				
				CGRect contentFrame = CGRectMake(0,self.view.bounds.origin.y + vertical_margin, 
												 self.view.bounds.size.width, 
												 self.view.bounds.size.height);
				
				if (nothingFound == nil)
					nothingFound = [[UIView alloc] initWithFrame:contentFrame];
				
				[nothingFound setBackgroundColor:[UIColor whiteColor]];
				
				[nothingFound addSubview:label];
                [label release];
				[self.view addSubview:nothingFound];
                //[nothingFound release];
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
		
        [self reloadDataForTableView:_eventListTableView];
        NSLog(@"jsonloaded: %@", [_eventListTableView description]);
        NSLog(@"jsonloaded: %@", [_eventListTableView.dataSource description]);
        NSLog(@"jsonloaded: %@", [_eventListTableView.delegate description]);
	}
}

- (BOOL)request:(JSONAPIRequest *)request shouldDisplayAlertForError:(NSError *)error {
    return YES;
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    [searchController setActive:YES animated:YES];
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error
{
	requestDispatched = NO;
    [self removeLoadingIndicator];
}


#pragma mark KGODatePagerDelegate

- (void)pager:(KGODatePager *)pager didSelectDate:(NSDate *)date {
    [startDate release];
    startDate = [date retain];    
    dateRangeDidChange = YES;

    [self reloadView:activeEventList];
    
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (self.events != nil) {
		return [self.events count];
	}
    return 0;
}

- (NSArray *)tableView:(UITableView *)tableView viewsForCellAtIndexPath:(NSIndexPath *)indexPath {
	MITCalendarEvent *event = [self.events objectAtIndex:indexPath.row];
	
    if (event.shortloc) {
        // right align event location
		CGFloat maxWidth = tableView.frame.size.width - 20;
		UIFont *font = [[KGOTheme sharedTheme] fontForTableCellTitleWithStyle:KGOTableCellStyleSubtitle];
		CGSize textSize = [event.title sizeWithFont:font];
		CGFloat textHeight = 10.0 + (textSize.width > maxWidth ? textSize.height * 1 : textSize.height);
		
		font = [[KGOTheme sharedTheme] fontForTableCellSubtitleWithStyle:KGOTableCellStyleSubtitle];
        CGSize locationTextSize = [event.shortloc sizeWithFont:font
													  forWidth:100.0
												 lineBreakMode:UILineBreakModeTailTruncation];
        CGRect locationFrame = CGRectMake(maxWidth - locationTextSize.width,
                                          textHeight,
                                          locationTextSize.width,
                                          locationTextSize.height);
        
        UILabel *locationLabel = [[[UILabel alloc] initWithFrame:locationFrame] autorelease];
        locationLabel.lineBreakMode = UILineBreakModeTailTruncation;
        locationLabel.text = event.shortloc;
        locationLabel.textColor = [[KGOTheme sharedTheme] textColorForTableCellSubtitleWithStyle:KGOTableCellStyleSubtitle];
        locationLabel.font = font;
        locationLabel.highlightedTextColor = [UIColor whiteColor];
        
		return [NSArray arrayWithObject:locationLabel];
    }
	
	return nil;
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath {
    
	MITCalendarEvent *event = [self.events objectAtIndex:indexPath.row];
	NSString *title = event.title;
    NSString *subtitle = nil;
	
	BOOL showTimeOnly = [CalendarConstants intervalForEventType:self.activeEventList fromDate:self.startDate forward:YES] == 86400.0;
    
    if (showTimeOnly) {
        subtitle = [event dateStringWithDateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle separator:@" "];
    } else {
		if (activeEventList == CalendarEventListTypeAcademic) {
			NSArray *stringArray = [[event dateStringWithDateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle separator:@" "] componentsSeparatedByString: @" "];
			subtitle = [stringArray objectAtIndex:0];
		} else {
			subtitle = [event dateStringWithDateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle separator:@" "];
		}
    }
	
    return [[^(UITableViewCell *cell) {
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.text = title;
		cell.detailTextLabel.text = subtitle;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } copy] autorelease];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	MITCalendarEvent *event = [self.events objectAtIndex:indexPath.row];
    
	CalendarDetailViewController *detailVC = [[CalendarDetailViewController alloc] initWithStyle:UITableViewStylePlain];
	detailVC.event = event;
	detailVC.events = self.events;
    
	[self.parentViewController.navigationController pushViewController:detailVC animated:YES];
	[detailVC release];
}

@end

