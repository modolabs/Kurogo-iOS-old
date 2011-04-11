#import "EventDetailTableView.h"
#import "CalendarModel.h"
#import "KGOContactInfo.h"
#import "UIKit+KGOAdditions.h"
#import "Foundation+KGOAdditions.h"
#import "KGORequestManager.h"
#import "KGODetailPageHeaderView.h"
#import "CalendarDataManager.h"
#import "MITMailComposeController.h"
#import "KGOAppDelegate+ModuleAdditions.h"

@implementation EventDetailTableView

@synthesize dataManager;

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
    
    NSLog(@"%@ %@ %@ %@", [_event description], _event.title, _event.location, _event.userInfo);
    
    [_sections release];
    NSMutableArray *mutableSections = [NSMutableArray array];
    NSArray *basicInfo = [self sectionForBasicInfo];
    if (basicInfo.count) {
        [mutableSections addObject:basicInfo];
    }

    NSArray *attendeeInfo = [self sectionForAttendeeInfo];
    if (attendeeInfo.count) {
        [mutableSections addObject:attendeeInfo];
    }

    NSArray *contactInfo = [self sectionForContactInfo];
    if (contactInfo.count) {
        [mutableSections addObject:contactInfo];
    }
    
    NSArray *extendedInfo = [self sectionForExtendedInfo];
    if (extendedInfo.count) {
        [mutableSections addObject:extendedInfo];
    }
    
    _sections = [mutableSections copy];
    
    [self reloadData];
    
    
    self.tableHeaderView = [self viewForTableHeader];
}



- (NSArray *)sectionForBasicInfo
{
    NSArray *basicInfo = nil;
    if (_event.location || _event.coordinate.latitude || _event.coordinate.longitude) {
        NSMutableDictionary *locationDict = [NSMutableDictionary dictionary];
        
        if (_event.briefLocation) {
            [locationDict setObject:_event.briefLocation forKey:@"title"];
            if (_event.location) {
                [locationDict setObject:_event.location forKey:@"subtitle"];
            }
            
        } else if (_event.location) {
            [locationDict setObject:_event.location forKey:@"title"];
        } else { // if we got this far there has to be a lat/lon
            [locationDict setObject:@"View on Map" forKey:@"title"];
        }

        if (_event.coordinate.latitude || _event.coordinate.longitude) {
            [locationDict setObject:KGOAccessoryTypeMap forKey: @"accessory"];
        }
        
        basicInfo = [NSArray arrayWithObject:locationDict];
    }
    NSLog(@"%@", basicInfo);
    return basicInfo;
}

- (NSArray *)sectionForAttendeeInfo
{
    NSArray *attendeeInfo = nil;
    if (_event.attendees) {
        NSString *attendeeString = [NSString stringWithFormat:@"%d %@",
                                    _event.attendees.count,
                                    NSLocalizedString(@"others attending", nil)];
        attendeeInfo = [NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                 attendeeString, @"title",
                                                 KGOAccessoryTypeChevron, @"accessory",
                                                 nil]];
    }
    return attendeeInfo;
}

- (NSArray *)sectionForContactInfo
{
    NSMutableArray *contactInfo = [NSMutableArray array];
    if (_event.organizers) {
        for (KGOAttendeeWrapper *organizer in _event.organizers) {
            for (KGOEventContactInfo *aContact in organizer.contactInfo) {
                NSString *type;
                NSString *accessory;
                NSString *url = nil;
                
                if ([aContact.type isEqualToString:@"phone"]) {
                    type = NSLocalizedString(@"Organizer phone", nil);
                    accessory = KGOAccessoryTypePhone;
                    url = [NSString stringWithFormat:@"tel:%@", aContact.value];
                    
                } else if ([aContact.type isEqualToString:@"email"]) {
                    type = NSLocalizedString(@"Organizer email", nil);
                    accessory = KGOAccessoryTypeEmail;
                    
                } else if ([aContact.type isEqualToString:@"url"]) {
                    type = NSLocalizedString(@"Event website", nil);
                    accessory = KGOAccessoryTypeExternal;
                    url = aContact.value;
                    
                } else {
                    type = NSLocalizedString(@"Contact", nil);
                    accessory = KGOAccessoryTypeNone;
                }
                
                NSDictionary *cellInfo;
                if (url) {
                    cellInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                type, @"title", aContact.value, @"subtitle", accessory, @"accessory", url, @"url", nil];
                } else {
                    cellInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                type, @"title", aContact.value, @"subtitle", accessory, @"accessory", nil];
                }
                
                
                [contactInfo addObject:cellInfo];
            }
        }
        
    }
    return contactInfo;
}

#define DESCRIPTION_LABEL_TAG 5

- (NSArray *)sectionForExtendedInfo
{
    NSArray *extendedInfo = nil;
    
    if (_event.summary) {
        UILabel *label = [UILabel multilineLabelWithText:_event.summary
                                                    font:[[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyBodyText]
                                                   width:self.frame.size.width - 20];
        label.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyBodyText];
        label.tag = DESCRIPTION_LABEL_TAG;
        CGRect frame = label.frame;
        frame.origin = CGPointMake(10, 10);
        label.frame = frame;
        
        extendedInfo = [NSArray arrayWithObject:label];
    }
    return extendedInfo;
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
    NSString *cellIdentifier;
    id cellData = [[_sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    if ([cellData isKindOfClass:[NSDictionary class]]) {    
        if ([cellData objectForKey:@"subtitle"]) {
            style = UITableViewCellStyleSubtitle;
        }
        cellIdentifier = [NSString stringWithFormat:@"%d", style];

    } else {
        cellIdentifier = [NSString stringWithFormat:@"%d.%d", indexPath.section, indexPath.row];
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:style reuseIdentifier:cellIdentifier] autorelease];

    } else {
        cell.imageView.image = nil;
        UIView *view = [cell viewWithTag:DESCRIPTION_LABEL_TAG];
        [view removeFromSuperview];
    }
        
    if ([cellData isKindOfClass:[NSDictionary class]]) {    
        cell.textLabel.text = [cellData objectForKey:@"title"];
        cell.detailTextLabel.text = [cellData objectForKey:@"subtitle"];
        if ([cellData objectForKey:@"image"]) {
            cell.imageView.image = [cellData objectForKey:@"image"];
        }
        
        NSString *accessory = [cellData objectForKey:@"accessory"];
        cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:accessory];
        if (accessory && ![accessory isEqualToString:KGOAccessoryTypeNone]) {
            cell.selectionStyle = UITableViewCellSelectionStyleGray;

        } else {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }

    } else {
        if ([cellData isKindOfClass:[UILabel class]]) {
            [cell.contentView addSubview:cellData];
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id cellData = [[_sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    if ([cellData isKindOfClass:[UILabel class]]) {
        return [(UILabel *)cellData frame].size.height + 20;
    }
    return tableView.rowHeight;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id cellData = [[_sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    if ([cellData isKindOfClass:[NSDictionary class]]) {    
        NSString *accessory = [cellData objectForKey:@"accessory"];
        NSURL *url = nil;
        NSString *urlString = [cellData objectForKey:@"url"];
        if (urlString) {
            url = [NSURL URLWithString:urlString];
        }
        
        if (url && [[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];

        } else if ([accessory isEqualToString:KGOAccessoryTypeEmail]) {
            [MITMailComposeController presentMailControllerWithEmail:[cellData objectForKey:@"subtitle"] subject:nil body:nil];
            
        } else if ([accessory isEqualToString:KGOAccessoryTypeMap]) {
            NSArray *annotations = [NSArray arrayWithObject:_event];
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:annotations, @"annotations", nil];
            [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameHome forModuleTag:MapTag params:params];
        }
    }
}

#pragma mark - Table header

- (void)headerViewFrameDidChange:(KGODetailPageHeaderView *)headerView
{
    if (_headerView.frame.size.height != self.tableHeaderView.frame.size.height) {
        self.tableHeaderView.frame = _headerView.frame;
    }
    self.tableHeaderView = self.tableHeaderView;
}

- (UIView *)viewForTableHeader
{
    if (!_headerView) {
        _headerView = [[KGODetailPageHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 1)];
        _headerView.delegate = self;
        _headerView.showsBookmarkButton = YES;
    }
    _headerView.detailItem = self.event;
    _headerView.showsShareButton = [self twitterUrl] != nil;
    
    // time
    NSString *dateString = [self.dataManager mediumDateStringFromDate:_event.startDate];
    NSString *timeString = nil;
    if (_event.endDate) {
        timeString = [NSString stringWithFormat:@"%@\n%@-%@",
                      dateString,
                      [self.dataManager shortTimeStringFromDate:_event.startDate],
                      [self.dataManager shortTimeStringFromDate:_event.endDate]];
    } else {
        timeString = [NSString stringWithFormat:@"%@\n%@",
                      dateString,
                      [self.dataManager shortTimeStringFromDate:_event.startDate]];
    }
    _headerView.subtitleLabel.text = timeString;
    
    return _headerView;
}

- (void)headerView:(KGODetailPageHeaderView *)headerView shareButtonPressed:(id)sender
{
    [_shareController shareInView:self];
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
