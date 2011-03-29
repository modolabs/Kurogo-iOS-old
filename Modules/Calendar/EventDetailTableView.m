#import "EventDetailTableView.h"
#import "CalendarModel.h"
#import "KGOContactInfo.h"
#import "ThemeConstants.h"
#import "UIKit+KGOAdditions.h"
#import "Foundation+KGOAdditions.h"
#import "KGORequestManager.h"

@interface EventDetailTableView (Private)

- (CGFloat)headerWidthWithButtons;
- (void)setupTableHeader;

- (void)share:(id)sender;
- (void)toggleBookmark:(id)sender;

@end


@implementation EventDetailTableView

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:style];
    if (self) {
        self.delegate = self;
        self.dataSource = self;
        
        _shareController = [(KGOShareButtonController *)[KGOShareButtonController alloc] initWithDelegate:self];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.delegate = self;
        self.dataSource = self;
        
        _shareController = [(KGOShareButtonController *)[KGOShareButtonController alloc] initWithDelegate:self];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.delegate = self;
        self.dataSource = self;
    }
    return self;
}

- (void)dealloc
{
	[_shareController release];
    [self hideShareButton];
    [self hideBookmarkButton];
    self.event = nil;
    self.delegate = nil;
    self.dataSource = nil;
    [super dealloc];
}

#pragma mark - Event

- (KGOEventWrapper *)event
{
    return _event;
}

- (void)setEvent:(KGOEventWrapper *)event
{
    [_event release];
    _event = [event retain];
    
    NSLog(@"%@ %@ %@", [_event description], _event.title, _event.location);
    
    [_sections release];
    NSMutableArray *mutableSections = [NSMutableArray array];

    NSMutableArray *basicInfo = [NSMutableArray array];
    if (_event.location) {
        if (_event.briefLocation) {
            [basicInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                  _event.briefLocation, @"title",
                                  _event.location, @"subtitle",
                                  TableViewCellAccessoryMap, @"accessory",
                                  nil]];
        } else {
            [basicInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                  _event.location, @"title",
                                  TableViewCellAccessoryMap, @"accessory",
                                  nil]];
        }
    }
    
    if (_event.attendees) {
        [basicInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                              [NSString stringWithFormat:@"%d others attending", _event.attendees.count], @"title",
                              KGOAccessoryTypeChevron, @"accessory",
                              nil]];
    }
    
    if (basicInfo.count) {
        [mutableSections addObject:basicInfo];
    }
    
    if (_event.organizers) {
        NSMutableArray *contactInfo = [NSMutableArray array];
        
        for (KGOAttendeeWrapper *organizer in _event.organizers) {
            for (KGOEventContactInfo *aContact in organizer.contactInfo) {
                NSString *type;
                NSString *accessory;
                if ([aContact.type isEqualToString:@"phone"]) {
                    type = NSLocalizedString(@"Organizer phone", nil);
                    accessory = TableViewCellAccessoryPhone;
                } else if ([aContact.type isEqualToString:@"email"]) {
                    type = NSLocalizedString(@"Organizer email", nil);
                    accessory = TableViewCellAccessoryEmail;
                } else if ([aContact.type isEqualToString:@"url"]) {
                    type = NSLocalizedString(@"Event website", nil);
                    accessory = TableViewCellAccessoryExternal;
                } else {
                    type = NSLocalizedString(@"Contact", nil);
                    accessory = KGOAccessoryTypeNone;
                }
                
                [contactInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                        type, @"title",
                                        aContact.value, @"subtitle",
                                        accessory, @"accessory",
                                        nil]];
            }
        }
        
        [mutableSections addObject:contactInfo];
    }
    
    _sections = [mutableSections copy];
    
    [self hideBookmarkButton];
    [self hideShareButton];
    [self setupTableHeader];
    [self reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[_sections objectAtIndex:section] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _sections.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCellStyle style = UITableViewCellStyleDefault;
    NSDictionary *cellData = [[_sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    if ([cellData objectForKey:@"subtitle"]) {
        style = UITableViewCellStyleSubtitle;
    }
    
    NSString *cellIdentifier = [NSString stringWithFormat:@"%d", style];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
    
    cell.textLabel.text = [cellData objectForKey:@"title"];
    cell.detailTextLabel.text = [cellData objectForKey:@"subtitle"];
    cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:[cellData objectForKey:@"accessory"]];
    
    return cell;
}

#pragma mark - UITableViewDelegate


#pragma mark - Table header

- (void)setupTableHeader
{
    self.tableHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 1)] autorelease];

    [self showShareButton];
    [self showBookmarkButton];
    
    // title
    UILabel *titleLabel = [UILabel multilineLabelWithText:_event.title
                                                     font:[[KGOTheme sharedTheme] fontForContentTitle]
                                                    width:[self headerWidthWithButtons] - 10];
    titleLabel.textColor = [[KGOTheme sharedTheme] textColorForContentTitle];
    
    // time
    // TODO: consolidate date formatter objects
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterNoStyle];
    NSString *dateString = [formatter stringFromDate:_event.startDate];
    
    [formatter setDateStyle:NSDateFormatterNoStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *timeString = [NSString stringWithFormat:@"%@\n%@-%@",
                            dateString,
                            [formatter stringFromDate:_event.startDate],
                            [formatter stringFromDate:_event.endDate]];
    UILabel *timeLabel = [UILabel multilineLabelWithText:timeString
                                                    font:[[KGOTheme sharedTheme] fontForBodyText]
                                                   width:[self headerWidthWithButtons] - 10];
    timeLabel.textColor = [[KGOTheme sharedTheme] textColorForBodyText];
    
    // description
    UILabel *summaryLabel = [UILabel multilineLabelWithText:_event.summary
                                                       font:[[KGOTheme sharedTheme] fontForTableFooter]
                                                      width:self.bounds.size.width - 10];
    summaryLabel.textColor = [[KGOTheme sharedTheme] textColorForBodyText];
    
    CGRect frame = titleLabel.frame;
    frame.origin.x = 10;
    frame.origin.y += 10;
    titleLabel.frame = frame;
    
    frame = timeLabel.frame;
    frame.origin.x = 10;
    frame.origin.y += titleLabel.frame.size.height + 20;
    timeLabel.frame = frame;
    
    frame = summaryLabel.frame;
    frame.origin.x = 10;
    frame.origin.y += titleLabel.frame.size.height + timeLabel.frame.size.height + 30;
    summaryLabel.frame = frame;
    
    frame = self.tableHeaderView.frame;
    frame.size.height = titleLabel.frame.size.height + timeLabel.frame.size.height + summaryLabel.frame.size.height + 40;
    self.tableHeaderView.frame = frame;
    
    [self.tableHeaderView addSubview:titleLabel];
    [self.tableHeaderView addSubview:timeLabel];
    [self.tableHeaderView addSubview:summaryLabel];
    
    self.tableHeaderView = self.tableHeaderView; // force contents to resize
}

- (CGFloat)headerWidthWithButtons
{
    // assuming share button occupies far right
    // and bookmark button comes after share
    CGFloat result = self.bounds.size.width - 10;
    if (_shareButton) {
        result -= _shareButton.frame.size.width + 10;
    }
    if (_bookmarkButton) {
        result -= _bookmarkButton.frame.size.width + 10;
    }
    return result;
}

- (void)showBookmarkButton
{
    if (!_bookmarkButton) {
        UIImage *placeholder = [UIImage imageWithPathName:@"common/bookmark_off.png"];
        CGFloat buttonX = [self headerWidthWithButtons] - placeholder.size.width;
        
        _bookmarkButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        _bookmarkButton.frame = CGRectMake(buttonX, 10, placeholder.size.width, placeholder.size.height);

        [_bookmarkButton addTarget:self action:@selector(toggleBookmark:) forControlEvents:UIControlEventTouchUpInside];
        [self.tableHeaderView addSubview:_bookmarkButton];
    }
    
    UIImage *buttonImage, *pressedButtonImage;
    if (_event.bookmarked) {
        buttonImage = [UIImage imageWithPathName:@"common/bookmark_on.png"];
        pressedButtonImage = [UIImage imageWithPathName:@"common/bookmark_on_pressed.png"];
    } else {
        buttonImage = [UIImage imageWithPathName:@"common/bookmark_off.png"];
        pressedButtonImage = [UIImage imageWithPathName:@"common/bookmark_off_pressed.png"];
    }
    [_bookmarkButton setImage:buttonImage forState:UIControlStateNormal];
    [_bookmarkButton setImage:pressedButtonImage forState:UIControlStateHighlighted];
}

- (void)showShareButton
{
    if (!_shareButton && [self twitterUrl]) {
        UIImage *buttonImage = [UIImage imageWithPathName:@"common/share.png"];
        CGFloat buttonX = [self headerWidthWithButtons] - buttonImage.size.width;
        
        _shareButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        _shareButton.frame = CGRectMake(buttonX, 10, buttonImage.size.width, buttonImage.size.height);
        [_shareButton setImage:buttonImage forState:UIControlStateNormal];
        [_shareButton setImage:[UIImage imageWithPathName:@"common/share_pressed.png"] forState:UIControlStateHighlighted];
        [_shareButton addTarget:self action:@selector(share:) forControlEvents:UIControlEventTouchUpInside];
        [self.tableHeaderView addSubview:_shareButton];
        
        if (_bookmarkButton) {
            CGRect frame = _bookmarkButton.frame;
            frame.origin.x = [self headerWidthWithButtons];
            _bookmarkButton.frame = frame;
        }
    }
}

- (void)hideBookmarkButton
{
    if (_bookmarkButton) {
        [_bookmarkButton removeFromSuperview];
        [_bookmarkButton release];
        _bookmarkButton = nil;
    }
}

- (void)hideShareButton
{
    if (_shareButton) {
        [_shareButton removeFromSuperview];
        [_shareButton release];
        _shareButton = nil;
    }
    
    // make sure bookmark button is flushed right
    if (_bookmarkButton) {
        CGRect frame = _bookmarkButton.frame;
        frame.origin.x = [self headerWidthWithButtons];
        _bookmarkButton.frame = frame;
    }
}

#pragma mark - button actions

- (void)share:(id)sender
{
    [_shareController shareInView:self];
}

- (void)toggleBookmark:(id)sender
{
    _event.bookmarked = !_event.bookmarked;
    [self showBookmarkButton];
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

@end
