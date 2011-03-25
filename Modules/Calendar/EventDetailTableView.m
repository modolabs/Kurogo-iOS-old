#import "EventDetailTableView.h"
#import "KGOEventWrapper.h"
#import "KGOAttendeeWrapper.h"
#import "KGOEventContactInfo.h"
#import "ThemeConstants.h"
#import "UIKit+KGOAdditions.h"

@implementation EventDetailTableView

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:style];
    if (self) {
        self.delegate = self;
        self.dataSource = self;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.delegate = self;
        self.dataSource = self;
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
        [basicInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                              @"Location Name", @"title",
                              _event.location, @"subtitle",
                              TableViewCellAccessoryMap, @"accessory",
                              nil]];
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

    // setup header

    // title
    UILabel *titleLabel = [UILabel multilineLabelWithText:_event.title
                                                     font:[[KGOTheme sharedTheme] fontForContentTitle]
                                                    width:self.frame.size.width];

    // time
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
                                                   width:self.frame.size.width];

    // description
    UILabel *summaryLabel = [UILabel multilineLabelWithText:_event.summary
                                                       font:[[KGOTheme sharedTheme] fontForTableFooter]
                                                      width:self.frame.size.width];
    
    CGRect frame = CGRectMake(0, 0, self.frame.size.width,
                              titleLabel.frame.size.height + timeLabel.frame.size.height + summaryLabel.frame.size.height + 40);
    UIView *headerView = [[[UIView alloc] initWithFrame:frame] autorelease];

    frame = titleLabel.frame;
    frame.origin.y += 10;
    titleLabel.frame = frame;
    
    frame = timeLabel.frame;
    frame.origin.y += titleLabel.frame.size.height + 20;
    timeLabel.frame = frame;
    
    frame = summaryLabel.frame;
    frame.origin.y += titleLabel.frame.size.height + timeLabel.frame.size.height + 30;
    summaryLabel.frame = frame;
    
    [headerView addSubview:titleLabel];
    [headerView addSubview:timeLabel];
    [headerView addSubview:summaryLabel];
    
    self.tableHeaderView = headerView;
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

@end
