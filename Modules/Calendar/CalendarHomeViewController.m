#import "CalendarHomeViewController.h"
#import "KGOAppDelegate.h"
#import "CalendarModel.h"

@implementation CalendarHomeViewController

@synthesize searchTerms;

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
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tabstrip.delegate = self;
    _datePager.delegate = self;
    
    _dataManager = [[CalendarDataManager alloc] init];
    _dataManager.delegate = self;
    [_dataManager requestGroups];
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


- (void)categoriesDidChange:(NSArray *)categories
{
}


- (void)eventsDidChange:(NSArray *)events category:(NSString *)category
{
}

#pragma mark - Scrolling tabstrip

- (void)tabstrip:(KGOScrollingTabstrip *)tabstrip clickedButtonAtIndex:(NSUInteger)index
{
    if (index != _currentGroupIndex) {
        _currentGroupIndex = index;
    }
}

- (void)setupTabstripButtons
{
    _tabstrip.showsSearchButton = YES;

    for (NSInteger i = 0; i < _groupTitles.count; i++) {
        NSString *buttonTitle = [_groupTitles objectAtIndex:i];
        [_tabstrip addButtonWithTitle:buttonTitle];
    }
    
    if (_currentGroupIndex >= _groupTitles.count) {
        _currentGroupIndex = 0;
    }
    
    [_tabstrip selectButtonAtIndex:_currentGroupIndex];
}

#pragma mark - Date pager

- (void)pager:(KGODatePager *)pager didSelectDate:(NSDate *)date
{
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
        KGOEventCategory *category = [_currentCategories objectAtIndex:indexPath.row];
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
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_currentCategories) {
        ;
        
    } else if (_currentSections && _currentEventsBySection) {
        NSArray *eventsForSection = [_currentEventsBySection objectForKey:[_currentSections objectAtIndex:indexPath.section]];
        KGOEventWrapper *event = [eventsForSection objectAtIndex:indexPath.row];
        
        NSDictionary *params = [NSDictionary dictionaryWithObject:event forKey:@"event"];
        [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail forModuleTag:CalendarTag params:params];
    }
}

@end
