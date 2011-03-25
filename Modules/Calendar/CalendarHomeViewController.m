#import "CalendarHomeViewController.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "CalendarModel.h"


@interface CalendarHomeViewController (Private)

- (void)clearEvents;
- (void)clearCalendars;

@end


@implementation CalendarHomeViewController

@synthesize searchTerms, currentCalendar = _currentCalendar;

/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}
*/

- (void)dealloc
{
    [self clearCalendars];
    [self clearEvents];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)clearEvents
{
    [_currentSections release];
    _currentSections = nil;
    
    [_currentEventsBySection release];
    _currentEventsBySection = nil;
}

- (void)clearCalendars
{
    [_currentCategories release];
    _currentCategories = nil;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Events";
    
    _currentGroupIndex = NSNotFound;
    
    _tabstrip.delegate = self;
    _datePager.delegate = self;
    
    _dataManager = [[CalendarDataManager alloc] init];
    _dataManager.delegate = self;
    [_dataManager requestGroups];
    
    [_datePager setDate:[NSDate date]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - CalendarDataManager

- (void)groupsDidChange:(NSArray *)groups
{
    [_groupTitles release];
    _groupTitles = [[NSMutableArray alloc] init];
    
    for (KGOCalendarGroup *aGroup in groups) {
        [_groupTitles addObject:aGroup.title];
    }
    
    [self setupTabstripButtons];
}

- (void)groupDataDidChange:(KGOCalendarGroup *)group
{
    NSLog(@"%@", [group.calendars description]);

    [self clearCalendars];
    [self clearEvents];
    
    if (group.calendars.count) {
        [_loadingView stopAnimating];
        
        UITableViewStyle style = (group.calendars.count > 1) ? UITableViewStyleGrouped : UITableViewStylePlain;
        if (group.calendars.count > 1) {
            style = UITableViewStyleGrouped;
            // TODO: sort
            _currentCategories = [[group.calendars allObjects] retain];
        } else {
            style = UITableViewStylePlain;
        }
        
        CGRect frame = self.view.frame;
        if ([_datePager isDescendantOfView:self.view]) {
            frame.origin.y += _datePager.frame.size.height;
            frame.size.height -= _datePager.frame.size.height;
        }
        if ([_tabstrip isDescendantOfView:self.view]) {
            frame.origin.y += _tabstrip.frame.size.height;
            frame.size.height -= _tabstrip.frame.size.height;
        }

        self.tableView = [self addTableViewWithFrame:frame style:style];
        
        self.currentCalendar = (group.calendars.count > 1) ? nil : [group.calendars anyObject];
    }
}

// TODO: flesh out placeholder functions
static bool isOverOneMonth(NSTimeInterval interval) {
    return interval > 31 * 24 * 60 * 60;
}

static bool isOverOneDay(NSTimeInterval interval) {
    return interval > 24 * 60 * 60;
}

static bool isOverOneHour(NSTimeInterval interval) {
    return interval > 60 * 60;
}


- (void)eventsDidChange:(NSArray *)events calendar:(KGOCalendar *)calendar
{
    if (_currentCalendar != calendar) {
        return;
    }
    
    [self clearEvents];
    
    if (events.count) {
        // TODO: make sure this set of events is what we last requested
        NSMutableDictionary *eventsBySection = [NSMutableDictionary dictionary];
        NSMutableArray *sectionTitles = [NSMutableArray array];
        NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES]];
        NSArray *sortedEvents = [events sortedArrayUsingDescriptors:sortDescriptors];
        KGOEventWrapper *firstEvent = [sortedEvents objectAtIndex:0];
        KGOEventWrapper *lastEvent = [sortedEvents lastObject];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        NSTimeInterval interval = [lastEvent.startDate timeIntervalSinceDate:firstEvent.startDate];
        if (isOverOneMonth(interval)) {
            [formatter setDateFormat:@"MMMM"];

        } else if (isOverOneDay(interval)) {
            [formatter setDateFormat:@"EEE MMMM d"];

        } else if (isOverOneHour(interval)) {
            [formatter setDateFormat:@"h a"];
        
        } else {
            [formatter setDateStyle:NSDateFormatterNoStyle];
            [formatter setTimeStyle:NSDateFormatterNoStyle];
        
        }
        
        for (KGOEventWrapper *event in events) {
            NSString *title = [formatter stringFromDate:event.startDate];
            NSMutableArray *eventsForCurrentSection = [eventsBySection objectForKey:title];
            if (!eventsForCurrentSection) {
                eventsForCurrentSection = [NSMutableArray array];
                [eventsBySection setObject:eventsForCurrentSection forKey:title];
                [sectionTitles addObject:title];
            }
            [eventsForCurrentSection addObject:event];
        }
    
        _currentSections = [sectionTitles copy];
        _currentEventsBySection = [eventsBySection copy];
    }
    
    [_loadingView stopAnimating];
    self.tableView.hidden = NO;
    [self reloadDataForTableView:self.tableView];
}



- (KGOCalendar *)currentCalendar
{
    return _currentCalendar;
}

- (void)setCurrentCalendar:(KGOCalendar *)currentCalendar
{
    [_currentCalendar release];
    _currentCalendar = [currentCalendar retain];
    
    if (_currentCalendar) {
        [_dataManager requestEventsForCalendar:_currentCalendar time:[NSDate date]];
    }
}

#pragma mark - Scrolling tabstrip

- (void)tabstrip:(KGOScrollingTabstrip *)tabstrip clickedButtonAtIndex:(NSUInteger)index
{
    // TODO: make tabstrip only return indexes of non-special buttons
    // since what it does now is way too confusing
    if (index == [tabstrip searchButtonIndex] || index == [tabstrip bookmarkButtonIndex]) {
        return;
    }
    
    NSString *title = [tabstrip buttonTitleAtIndex:index];
    index = [_groupTitles indexOfObject:title];
    
    if (index != _currentGroupIndex) {
        [self removeTableView:self.tableView];
        [_loadingView startAnimating];

        _currentGroupIndex = index;
        [_dataManager selectGroupAtIndex:index];
        KGOCalendarGroup *group = [_dataManager currentGroup];
        [self groupDataDidChange:group];
    }
}

- (void)setupTabstripButtons
{
    _tabstrip.showsSearchButton = NO;

    for (NSInteger i = 0; i < _groupTitles.count; i++) {
        NSString *buttonTitle = [_groupTitles objectAtIndex:i];
        [_tabstrip addButtonWithTitle:buttonTitle];
    }
    [_tabstrip setNeedsLayout];
    
    // TODO: preserve previous selection if any
    [_tabstrip selectButtonAtIndex:0];
}

#pragma mark - Date pager

- (void)pager:(KGODatePager *)pager didSelectDate:(NSDate *)date
{
    [_loadingView startAnimating];
    self.tableView.hidden = YES;
    
    if (_currentCalendar) {
        //[_dataManager requestEventsForCalendar:_currentCalendar startDate:date endDate:nil];
    }
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger num = 1;
    if (_currentSections && _currentEventsBySection) {
        num = _currentSections.count;
    }
    return num;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger num = 0;
    if (_currentSections && _currentEventsBySection) {
        NSArray *eventsForSection = [_currentEventsBySection objectForKey:[_currentSections objectAtIndex:section]];
        num = eventsForSection.count;

    } else if (_currentCategories) {
        num = _currentCategories.count;
    }

    return num;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (_currentSections.count > 1) {
        return [_currentSections objectAtIndex:section];
    }
    
    return nil;
}

- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath {
    if (_currentCategories) {
        return UITableViewCellStyleDefault;
    }
    return UITableViewCellStyleSubtitle;
}

- (NSArray *)tableView:(UITableView *)tableView viewsForCellAtIndexPath:(NSIndexPath *)indexPath {
    if (!_currentCategories && _currentSections && _currentEventsBySection) {
        NSArray *eventsForSection = [_currentEventsBySection objectForKey:[_currentSections objectAtIndex:indexPath.section]];
        KGOEventWrapper *event = [eventsForSection objectAtIndex:indexPath.row];
    
        if (event.briefLocation) {
            // right align event location
            CGFloat maxWidth = tableView.frame.size.width - 20;
            UIFont *font = [[KGOTheme sharedTheme] fontForTableCellTitleWithStyle:KGOTableCellStyleSubtitle];
            CGSize textSize = [event.title sizeWithFont:font];
            CGFloat textHeight = 10.0 + (textSize.width > maxWidth ? textSize.height * 1 : textSize.height);
            
            font = [[KGOTheme sharedTheme] fontForTableCellSubtitleWithStyle:KGOTableCellStyleSubtitle];
            CGSize locationTextSize = [event.briefLocation sizeWithFont:font
                                                               forWidth:100.0
                                                          lineBreakMode:UILineBreakModeTailTruncation];
            CGRect locationFrame = CGRectMake(maxWidth - locationTextSize.width,
                                              textHeight,
                                              locationTextSize.width,
                                              locationTextSize.height);
            
            UILabel *locationLabel = [[[UILabel alloc] initWithFrame:locationFrame] autorelease];
            locationLabel.lineBreakMode = UILineBreakModeTailTruncation;
            locationLabel.text = event.briefLocation;
            locationLabel.textColor = [[KGOTheme sharedTheme] textColorForTableCellSubtitleWithStyle:KGOTableCellStyleSubtitle];
            locationLabel.font = font;
            locationLabel.highlightedTextColor = [UIColor whiteColor];
            
            return [NSArray arrayWithObject:locationLabel];
        }
    
    }
    
	return nil;
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath {
    if (_currentCategories) {
        KGOCalendar *category = [_currentCategories objectAtIndex:indexPath.row];
        NSString *title = category.title;
        
        return [[^(UITableViewCell *cell) {
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.textLabel.text = title;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } copy] autorelease];
        
    } else if (_currentSections && _currentEventsBySection) {
        NSArray *eventsForSection = [_currentEventsBySection objectForKey:[_currentSections objectAtIndex:indexPath.section]];
        KGOEventWrapper *event = [eventsForSection objectAtIndex:indexPath.row];
        
        NSString *title = event.title;
        NSString *subtitle = nil; // TODO: put some date string here
        
        return [[^(UITableViewCell *cell) {
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.textLabel.text = title;
            cell.detailTextLabel.text = subtitle;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } copy] autorelease];
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_currentCategories) {
        KGOCalendar *calendar = [_currentCategories objectAtIndex:indexPath.row];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:calendar, @"calendar", nil];
        [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameCategoryList forModuleTag:CalendarTag params:params];
        
    } else if (_currentSections && _currentEventsBySection) {
        NSArray *eventsForSection = [_currentEventsBySection objectForKey:[_currentSections objectAtIndex:indexPath.section]];
        KGOEventWrapper *event = [eventsForSection objectAtIndex:indexPath.row];
        NSDictionary *params = [NSDictionary dictionaryWithObject:event forKey:@"event"];
        [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail forModuleTag:CalendarTag params:params];
    }
}

@end
