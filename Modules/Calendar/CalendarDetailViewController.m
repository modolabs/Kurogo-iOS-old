#import "CalendarDetailViewController.h"
#import "EventDetailTableView.h"
#import "KGOEventWrapper.h"
#import "KGOCalendar.h"
#import "KGOAttendeeWrapper.h"
#import "KGOContactInfo.h"
#import "KGORequestManager.h"
#import "Foundation+KGOAdditions.h"
#import "UIKit+KGOAdditions.h"
#import "CalendarDataManager.h"

@implementation CalendarDetailViewController

@synthesize sections, eventsBySection, indexPath, dataManager;

- (void)loadView {
    [super loadView];

    self.title = NSLocalizedString(@"Event Detail", nil);
    
    [self setupTableView];
}

- (void)viewDidLoad
{
    KGODetailPager *pager = [[[KGODetailPager alloc] initWithPagerController:self delegate:self] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:pager] autorelease];
    if (self.indexPath) {
        [pager selectPageAtSection:self.indexPath.section row:self.indexPath.row];
    }
}

- (void)setupTableView
{
    if (!_tableView) {
        CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        _tableView = [[EventDetailTableView alloc] initWithFrame:frame style:UITableViewStyleGrouped];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.dataManager = self.dataManager;
        
        [self.view addSubview:_tableView];
    }
}

#pragma mark - KGODetailPager

- (void)pager:(KGODetailPager *)pager showContentForPage:(id<KGOSearchResult>)content
{
    if ([content isKindOfClass:[KGOEventWrapper class]]) {
        [_event release];
        _event = [content retain];
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

#pragma mark -

- (void)dealloc {
    [_event release];
    [_tableView release];
    self.dataManager = nil;
    self.sections = nil;
    self.indexPath = nil;
    self.eventsBySection = nil;
    [super dealloc];
}

@end
