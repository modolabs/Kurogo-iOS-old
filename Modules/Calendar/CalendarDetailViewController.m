#import "CalendarDetailViewController.h"
#import "EventDetailTableView.h"
#import "KGOEventWrapper.h"
#import "KGOCalendar.h"
#import "KGOAttendeeWrapper.h"
#import "KGOContactInfo.h"
#import "KGORequestManager.h"
#import "Foundation+KGOAdditions.h"
#import "UIKit+KGOAdditions.h"

@implementation CalendarDetailViewController

@synthesize sections, eventsBySection, indexPath;

- (void)loadView {
    [super loadView];

	CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    _tableView = [[EventDetailTableView alloc] initWithFrame:frame style:UITableViewStyleGrouped];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.backgroundColor = [[KGOTheme sharedTheme] backgroundColorForApplication];
    
    [self.view addSubview:_tableView];

	_shareController = [(KGOShareButtonController *)[KGOShareButtonController alloc] initWithDelegate:self];
    [self setupShareButton];

    self.title = @"Event Detail";
    
    KGODetailPager *pager = [[[KGODetailPager alloc] initWithPagerController:self delegate:self] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:pager] autorelease];
    if (self.indexPath) {
        [pager selectPageAtSection:self.indexPath.section row:self.indexPath.row];
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
    NSString *sectionName = [self.sections objectAtIndex:indexPath.section];
    return [[self.eventsBySection objectForKey:sectionName] count];
}

- (NSInteger)numberOfSections:(KGODetailPager *)pager
{
    return self.sections.count;
}

#pragma mark - share button

- (void)share:(id)sender {
    [_shareController shareInView:self.view];
}

- (void)setupShareButton {
    UIButton *shareButton = (UIButton *)[self.view viewWithTag:5535];
    
    if (!shareButton) {
        UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        shareButton.tag = 5535;
        UIImage *buttonImage = [UIImage imageWithPathName:@"common/share.png"];
        shareButton.frame = CGRectMake(self.view.bounds.size.width - buttonImage.size.width - 10,
                                       10, buttonImage.size.width,
                                       buttonImage.size.height);
        [shareButton setImage:buttonImage forState:UIControlStateNormal];
        [shareButton setImage:[UIImage imageNamed:@"common/share_pressed.png"] 
                     forState:(UIControlStateNormal | UIControlStateHighlighted)];
        [shareButton addTarget:self action:@selector(share:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:shareButton];
    }
}


#pragma mark KGOShareButtonDelegate

- (NSString *)actionSheetTitle {
	return [NSString stringWithString:@"Share this event"];
}

- (NSString *)emailSubject {
    return _event.title;
}

- (NSString *)emailBody {
	return [NSString stringWithFormat:@"I thought you might be interested in this event...\n%@\n%@\n%@",
            _event.title,
            [self twitterUrl],
            _event.summary];
}

- (NSString *)fbDialogPrompt {
	return nil;
}

- (NSString *)fbDialogAttachment {
    NSString *attachment = [NSString stringWithFormat:
                            @"{\"name\":\"%@\","
                            "\"href\":\"%@\","
                            "\"description\":\"%@\"}",
                            _event.title, [self twitterUrl], _event.summary];
    return attachment;
}

- (NSString *)twitterUrl {
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
    
    return urlString;
}

- (NSString *)twitterTitle {
	return _event.title;
}

- (void)dealloc {
    [_event release];
    [_tableView release];
	[_shareController release];
    self.sections = nil;
    self.indexPath = nil;
    self.eventsBySection = nil;
    [super dealloc];
}

@end
