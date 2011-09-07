#import "CalendarDetailViewController.h"
#import "EventDetailTableView.h"
#import "KGOEventWrapper.h"
#import "KGOAttendeeWrapper.h"
#import "KGOContactInfo.h"
#import "KGORequestManager.h"
#import "Foundation+KGOAdditions.h"
#import "UIKit+KGOAdditions.h"
#import "CalendarDataManager.h"
#import "KGOShareButtonController.h"

@implementation CalendarDetailViewController

@synthesize sections, eventsBySection, indexPath, dataManager, searchResult;

- (void)loadView {
    [super loadView];

    self.title = NSLocalizedString(@"Event Detail", nil);
    
    _shareController = [(KGOShareButtonController *)[KGOShareButtonController alloc] initWithContentsController:self];
    _shareController.shareTypes = KGOShareControllerShareTypeEmail | KGOShareControllerShareTypeFacebook | KGOShareControllerShareTypeTwitter;
    
    [self setupTableView];
}

- (void)viewDidLoad
{
    KGODetailPager *pager = [[[KGODetailPager alloc] initWithPagerController:self delegate:self] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:pager] autorelease];
    if (self.indexPath) {
        [pager selectPageAtSection:self.indexPath.section row:self.indexPath.row];
    }
    else if(self.searchResult){
        [self pager:pager showContentForPage:searchResult];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSIndexPath *selectedIndexPath = [_tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        [_tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
    }
}

- (void)setupTableView
{
    if (!_tableView) {
        CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        _tableView = [[EventDetailTableView alloc] initWithFrame:frame style:UITableViewStyleGrouped];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.viewController = self;
        _tableView.dataManager = self.dataManager;
        
        [self.view addSubview:_tableView];
    }
    
    [_tableView reloadData];
}

#pragma mark - KGODetailPager

- (void)pager:(KGODetailPager *)pager showContentForPage:(id<KGOSearchResult>)content
{
    if ([content isKindOfClass:[KGOEventWrapper class]]) {
        [_event release];
        _event = [(KGOEventWrapper *)content retain];
        _tableView.event = _event;
    }
}

- (id<KGOSearchResult>)pager:(KGODetailPager *)pager contentForPageAtIndexPath:(NSIndexPath *)anIndexPath
{
    NSString *sectionName = [self.sections objectAtIndex:anIndexPath.section];
    NSArray *events = [self.eventsBySection objectForKey:sectionName];
    return [events objectAtIndex:anIndexPath.row];
}

- (NSInteger)pager:(KGODetailPager *)pager numberOfPagesInSection:(NSInteger)section
{
    NSString *sectionName = [self.sections objectAtIndex:section];
    return [[self.eventsBySection objectForKey:sectionName] count];
}

- (NSInteger)numberOfSections:(KGODetailPager *)pager
{
    return self.sections.count;
}

#pragma mark - Share button

- (void)shareButtonPressed:(id)sender
{
    _shareController.actionSheetTitle = @"Share this event";
    _shareController.shareTitle = _event.title;
    _shareController.shareBody = _event.summary;
    
    NSString *urlString = nil;
    for (KGOAttendeeWrapper *organizer in _event.organizers) {
        for (KGOContactInfo *contact in organizer.contactInfo) {
            if ([contact.type isEqualToString:@"url"]) {
                urlString = contact.value;
                break;
            }
        }
        if (urlString)
            break;
    }
    
    if (!urlString) {
        KGOCalendar *calendar = [_event.calendars anyObject];
        NSString *startString = [NSString stringWithFormat:@"%.0f", [_event.startDate timeIntervalSince1970]];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                _event.identifier, @"id",
                                calendar.identifier, @"calendar",
                                calendar.type, @"type",
                                startString, @"time",
                                nil];
        
        urlString = [[NSURL URLWithQueryParameters:params baseURL:[[KGORequestManager sharedManager] serverURL]] absoluteString];
    }
    
    _shareController.shareURL = urlString;
    
    [_shareController shareInView:self.view];
}

#pragma mark EKEventEditViewDelegate
- (void)eventEditViewController:(EKEventEditViewController *)controller 
          didCompleteWithAction:(EKEventEditViewAction)action {
    [controller dismissModalViewControllerAnimated:YES];
}

#pragma mark -

- (void)dealloc {
    [_event release];
    [_tableView release];
	[_shareController release];
    self.dataManager = nil;
    self.sections = nil;
    self.indexPath = nil;
    self.eventsBySection = nil;
    [super dealloc];
}

@end
