#import "CalendarHomeViewController.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "CalendarModel.h"
#import "CalendarDetailViewController.h"
#import "UIKit+KGOAdditions.h"

@interface CalendarHomeViewController (Private)

- (void)requestEventsForCurrentCalendar:(NSDate *)date;
- (void)loadTableViewWithStyle:(UITableViewStyle)style;

@end


// TODO: flesh out placeholder functions
bool isOverOneMonth(NSTimeInterval interval) {
    return interval > 31 * 24 * 60 * 60;
}

bool isOverOneDay(NSTimeInterval interval) {
    return interval > 24 * 60 * 60;
}

bool isOverOneHour(NSTimeInterval interval) {
    return interval > 60 * 60;
}


@implementation CalendarHomeViewController

@synthesize federatedSearchTerms, dataManager, moduleTag, showsGroups, currentCalendar = _currentCalendar;
@synthesize currentSections = _currentSections, currentEventsBySection = _currentEventsBySection,
groupTitles = _groupTitles;
@synthesize federatedSearchResults;

- (void)dealloc
{
    self.dataManager = nil;
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
    self.currentSections = nil;
    self.currentEventsBySection = nil;
}

- (void)clearCalendars
{
    [_currentCalendars release];
    _currentCalendars = nil;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _currentGroupIndex = NSNotFound;
    
    _datePager.contentsController = self;
    _datePager.delegate = self;
    
    if (self.showsGroups) {
        _tabstrip.delegate = self;
        _tabstrip.showsSearchButton = YES;
        
        [self.dataManager requestGroups]; // response to this will populate the tabstrip
        
    } else {
        _tabstrip.hidden = YES;
        CGRect frame = _datePager.frame;
        frame.origin.y = _tabstrip.frame.origin.y;
        _datePager.frame = frame;
    }
    
    [_datePager setDate:[NSDate date]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.dataManager.delegate = self;
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
    self.groupTitles = [NSMutableArray array];
    
    for (KGOCalendarGroup *aGroup in groups) {
        [self.groupTitles addObject:aGroup.title];
    }
    
    if (self.groupTitles.count == 1) {
        // if there's only one group, expand the calendars in this group
        [self.dataManager requestCalendarsForGroup:[groups objectAtIndex:0]];
        
    } else {
        [self setupTabstripButtons];
    }
}

- (void)groupDataDidChange:(KGOCalendarGroup *)group
{
    [self clearCalendars];
    [self clearEvents];
    
    if (group.calendars.count) {
        [_loadingView stopAnimating];
        
        UITableViewStyle style;

        if (group.calendars.count > 1) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES];
            _currentCalendars = [[group.calendars sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]] retain];
            
            if (self.groupTitles.count == 1) {
                style = UITableViewStylePlain;
                _datePager.hidden = NO;
                
                [self setupTabstripButtons];
                
            } else {
                style = UITableViewStyleGrouped;
                _datePager.hidden = YES;
            }

        } else {
            style = UITableViewStylePlain;
            _datePager.hidden = NO;
        }
        
        [self loadTableViewWithStyle:style];

        if (group.calendars.count == 1) {
            // only one calendar so just pick it
            self.currentCalendar = [group.calendars anyObject];
        } else if (self.groupTitles.count > 1) {
            // multiple groups and multiple calendars -- show list of calendars in table view
            self.currentCalendar = nil;
        } else {
            // multiple calendars in this group -- select the first
            self.currentCalendar = [_currentCalendars objectAtIndex:0];
        }
        
    } else {
        [self.dataManager requestCalendarsForGroup:group];
    }
}

- (void)loadTableViewWithStyle:(UITableViewStyle)style
{
    CGRect frame = self.view.frame;
    if (!_datePager.hidden && [_datePager isDescendantOfView:self.view]) {
        frame.origin.y += _datePager.frame.size.height;
        frame.size.height -= _datePager.frame.size.height;
    }
    if (!_tabstrip.hidden && [_tabstrip isDescendantOfView:self.view]) {
        frame.origin.y += _tabstrip.frame.size.height;
        frame.size.height -= _tabstrip.frame.size.height;
    }
    self.tableView = [self addTableViewWithFrame:frame style:style];

    if (self.federatedSearchTerms || self.federatedSearchResults) {
        [_tabstrip showSearchBarAnimated:NO];
        [_tabstrip.searchController setActive:NO animated:NO];
        _tabstrip.searchController.searchBar.text = self.federatedSearchTerms;
        
        if (self.federatedSearchResults) {
            [_tabstrip.searchController setSearchResults:self.federatedSearchResults
                                            forModuleTag:self.dataManager.moduleTag];
        }
    }
}


- (void)eventsDidChange:(NSArray *)events calendar:(KGOCalendar *)calendar
{
    if (_currentCalendar != calendar) {
        return;
    }
    
    [self clearEvents];
    
    NSMutableArray *sectionTitles = [NSMutableArray array];
    NSMutableDictionary *eventsBySection = [NSMutableDictionary dictionary];
    
    if (events.count) {
        // TODO: make sure this set of events is what we last requested
        NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES]];
        NSArray *sortedEvents = [events sortedArrayUsingDescriptors:sortDescriptors];
        KGOEventWrapper *firstEvent = [sortedEvents objectAtIndex:0];
        KGOEventWrapper *lastEvent = [sortedEvents lastObject];
        NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
        NSTimeInterval interval = [lastEvent.startDate timeIntervalSinceDate:firstEvent.startDate];
        if (isOverOneMonth(interval)) {
            [formatter setDateFormat:@"MMMM"];

        } else if (isOverOneDay(interval)) {
            [formatter setDateFormat:@"EEE MMMM d"];

        } else if (isOverOneHour(interval)) {
            [formatter setDateFormat:@"h a"];
        
        } else {
           // [formatter setDateStyle:NSDateFormatterNoStyle];
           // [formatter setTimeStyle:NSDateFormatterNoStyle];
            [formatter setDateFormat:@"h a"]; // default to hourly format
        }
        
        for (KGOEventWrapper *event in sortedEvents) {
            NSString *title = [formatter stringFromDate:event.startDate];
            NSMutableArray *eventsForCurrentSection = [eventsBySection objectForKey:title];
            if (!eventsForCurrentSection) {
                eventsForCurrentSection = [NSMutableArray array];
                [eventsBySection setObject:eventsForCurrentSection forKey:title];
                [sectionTitles addObject:title];
            }
            [eventsForCurrentSection addObject:event];
        }
    }
    
    self.currentSections = sectionTitles;
    self.currentEventsBySection = eventsBySection;
    
    [_loadingView stopAnimating];

    if (!self.tableView) {
        [self loadTableViewWithStyle:UITableViewStylePlain];
    } else {
        self.tableView.hidden = NO;
        [self reloadDataForTableView:self.tableView];
    }
}


- (KGOCalendar *)currentCalendar
{
    return _currentCalendar;
}

- (void)setCurrentCalendar:(KGOCalendar *)currentCalendar
{
    [_currentCalendar release];
    _currentCalendar = [currentCalendar retain];
    
    [self requestEventsForCurrentCalendar:[NSDate date]];
}

- (void)requestEventsForCurrentCalendar:(NSDate *)date
{
    if (_currentCalendar) {
        self.tableView.hidden = YES;
        [_loadingView startAnimating];
        [self.dataManager requestEventsForCalendar:_currentCalendar time:date];
    }
}

#pragma mark - Scrolling tabstrip

- (void)tabstrip:(KGOScrollingTabstrip *)tabstrip clickedButtonAtIndex:(NSUInteger)index
{
    if (index != _currentGroupIndex) {
        [self removeTableView:self.tableView];
        [_loadingView startAnimating];

        _currentGroupIndex = index;

        if (self.groupTitles.count > 1) {
            [self.dataManager selectGroupAtIndex:_currentGroupIndex];
            KGOCalendarGroup *group = [self.dataManager currentGroup];
            [self groupDataDidChange:group];

        } else if (_currentGroupIndex >= 0 && _currentGroupIndex < _currentCalendars.count) {
            self.currentCalendar = [_currentCalendars objectAtIndex:_currentGroupIndex];
        }
    }
}

- (void)setupTabstripButtons
{
    NSUInteger selectedButtonIndex = [_tabstrip indexOfSelectedButton];

    [_tabstrip removeAllRegularButtons];
    if (self.groupTitles.count == 1) {
        for (KGOCalendar *aCalendar in _currentCalendars) {
            [_tabstrip addButtonWithTitle:aCalendar.title];
        }
    
    } else {
        for (NSString *buttonTitle in self.groupTitles) {
            [_tabstrip addButtonWithTitle:buttonTitle];
        }
    }
    [_tabstrip setNeedsLayout];
    
    if (selectedButtonIndex < [_tabstrip numberOfButtons]) {
        [_tabstrip selectButtonAtIndex:selectedButtonIndex];
    } else if ([_tabstrip numberOfButtons]) {
        [_tabstrip selectButtonAtIndex:0];
    }
}

#pragma mark - Date pager

- (void)pager:(KGODatePager *)pager didSelectDate:(NSDate *)date
{
    [self requestEventsForCurrentCalendar:date];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger num = 1;
    if (self.currentSections && self.currentEventsBySection) {
        if (self.currentSections.count) {
            num = self.currentSections.count;
        } else {
            num = 1; // error message
        }
    }
    return num;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger num = 0;
    if (self.currentSections && self.currentEventsBySection) {
        if (self.currentSections.count) {
            NSArray *eventsForSection = [self.currentEventsBySection objectForKey:[self.currentSections objectAtIndex:section]];
            num = eventsForSection.count;
        } else {
            num = 1; // error message
        }
    } else if (_currentCalendars) {
        num = _currentCalendars.count;
    }

    return num;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.currentSections.count >= 1) {
        return [self.currentSections objectAtIndex:section];
    }
    
    return nil;
}

- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath {
    if (_currentCalendars && self.groupTitles.count > 1) {
        return KGOTableCellStyleDefault;
    }
    return KGOTableCellStyleSubtitle;
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath {
    if (_currentCalendars && self.groupTitles.count > 1) {
        KGOCalendar *category = [_currentCalendars objectAtIndex:indexPath.row];
        NSString *title = category.title;
        
        return [[^(UITableViewCell *cell) {
            [cell applyBackgroundThemeColorForIndexPath:indexPath tableView:tableView];
            cell.textLabel.text = title;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } copy] autorelease];
        
    } else if (self.currentSections && self.currentEventsBySection) {
        if (self.currentSections.count) {
            NSArray *eventsForSection = [self.currentEventsBySection objectForKey:[self.currentSections objectAtIndex:indexPath.section]];
            KGOEventWrapper *event = [eventsForSection objectAtIndex:indexPath.row];
            
            NSString *title = title = event.title;
            NSString *subtitle = nil;
            if (event.allDay) {
                subtitle = [NSString stringWithFormat:@"%@ %@", [self.dataManager shortDateStringFromDate:event.startDate], NSLocalizedString(@"All day", nil)];
            } else {
                subtitle = [self.dataManager shortDateTimeStringFromDate:event.startDate];
            }
            return [[^(UITableViewCell *cell) {
                [cell applyBackgroundThemeColorForIndexPath:indexPath tableView:tableView];
                cell.textLabel.text = title;
                cell.detailTextLabel.text = subtitle;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            } copy] autorelease];
        } else {
            return [[^(UITableViewCell *cell) {
                cell.textLabel.text = NSLocalizedString(@"No events found", nil);
                cell.textLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListTitle];
                cell.textLabel.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListTitle];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.accessoryType = UITableViewCellAccessoryNone;
            } copy] autorelease];
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_currentCalendars && self.groupTitles.count > 1) {
        KGOCalendar *calendar = [_currentCalendars objectAtIndex:indexPath.row];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:calendar, @"calendar", nil];
        [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameCategoryList forModuleTag:self.moduleTag params:params];
        
    } else if (self.currentSections && self.currentEventsBySection && self.currentSections.count) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                self.currentEventsBySection, @"eventsBySection",
                                self.currentSections, @"sections",
                                indexPath, @"currentIndexPath",
                                nil];
                               
        [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail forModuleTag:self.moduleTag params:params];
    }
}

- (BOOL)tabstripShouldShowSearchDisplayController:(KGOScrollingTabstrip *)tabstrip
{
    return YES;
}

- (UIViewController *)viewControllerForTabstrip:(KGOScrollingTabstrip *)tabstrip
{
    return self;
}

#pragma mark KGOSearchDisplayDelegate

- (BOOL)searchControllerShouldShowSuggestions:(KGOSearchDisplayController *)controller {
    return NO;
}

- (NSArray *)searchControllerValidModules:(KGOSearchDisplayController *)controller {
    return [NSArray arrayWithObject:self.moduleTag];
}

- (NSString *)searchControllerModuleTag:(KGOSearchDisplayController *)controller {
    return self.moduleTag;
}

- (void)resultsHolder:(id<KGOSearchResultsHolder>)resultsHolder didSelectResult:(id<KGOSearchResult>)aResult{
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            _currentEventsBySection, @"eventsBySection",
                            _currentSections, @"sections",
                            aResult, @"searchResult",
                            nil];
    
    [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail forModuleTag:self.moduleTag params:params];

}


- (void)searchController:(KGOSearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView {
    self.federatedSearchTerms = nil;
    self.federatedSearchResults = nil;
    [_tabstrip hideSearchBarAnimated:YES];
    [self setupTabstripButtons];
    [_tabstrip selectButtonAtIndex:_currentGroupIndex];
}


@end
