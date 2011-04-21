#import "CalendarDataManager.h"
#import "CoreDataManager.h"
#import "Foundation+KGOAdditions.h"
#import "CalendarModel.h"

#define EVENT_TIMEOUT -3600

@implementation CalendarDataManager

@synthesize delegate, moduleTag;

- (id)init
{
    self = [super init];
    if (self) {
        NSDateFormatter *mediumDayDF = [[[NSDateFormatter alloc] init] autorelease];
        [mediumDayDF setDateStyle:NSDateFormatterMediumStyle];
        [mediumDayDF setTimeStyle:NSDateFormatterNoStyle];
        NSDateFormatter *shortTimeDF = [[[NSDateFormatter alloc] init] autorelease];
        [shortTimeDF setDateStyle:NSDateFormatterNoStyle];
        [shortTimeDF setTimeStyle:NSDateFormatterShortStyle];
        NSDateFormatter *dateTimeDF = [[[NSDateFormatter alloc] init] autorelease];
        [dateTimeDF setDateStyle:NSDateFormatterShortStyle];
        [dateTimeDF setTimeStyle:NSDateFormatterShortStyle];
        
        //NSDateFormatter *DF = [[[NSDateFormatter alloc] init] autorelease];
        
        
        _dateFormatters = [[NSDictionary alloc] initWithObjectsAndKeys:
                           mediumDayDF, @"mediumDay",
                           shortTimeDF, @"shortTime",
                           dateTimeDF, @"dateTime",
                           nil];
    }
    return self;
}

- (NSString *)mediumDateStringFromDate:(NSDate *)date
{
    return [[_dateFormatters objectForKey:@"mediumDay"] stringFromDate:date];
}

- (NSString *)shortTimeStringFromDate:(NSDate *)date
{
    return [[_dateFormatters objectForKey:@"shortTime"] stringFromDate:date];
}

- (NSString *)shortDateTimeStringFromDate:(NSDate *)date
{
    return [[_dateFormatters objectForKey:@"dateTime"] stringFromDate:date];
}

- (KGOCalendarGroup *)currentGroup
{
    return _currentGroup;
}

- (void)selectGroupAtIndex:(NSInteger)index
{
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"sortOrder = %d", index];
    KGOCalendarGroup *group = [[[CoreDataManager sharedManager] objectsForEntity:KGOEntityNameCalendarGroup
                                                               matchingPredicate:pred] lastObject];
    if (group) {
        [_currentGroup release];
        _currentGroup = [group retain];
    }
}

- (BOOL)requestGroups
{
    BOOL success = NO;
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES];
    NSArray *oldGroups = [[CoreDataManager sharedManager] objectsForEntity:KGOEntityNameCalendarGroup
                                                         matchingPredicate:nil
                                                           sortDescriptors:[NSArray arrayWithObject:sort]];
    
    if (oldGroups) {
        success = YES;
        [self.delegate groupsDidChange:oldGroups];
    }
    
    if ([[KGORequestManager sharedManager] isReachable]) {
        if(_groupsRequest) {
            return success;
        }
        
        _groupsRequest = [[KGORequestManager sharedManager] requestWithDelegate:self module:self.moduleTag path:@"groups" params:nil];
        _groupsRequest.expectedResponseType = [NSDictionary class];
        [_groupsRequest connect];
    }
    return success;
}

- (BOOL)requestEventsForCalendar:(KGOCalendar *)calendar params:(NSDictionary *)params
{
    BOOL success = NO;
    DLog(@"%@", params);    
    NSArray *events = [calendar.events allObjects];
    if (events.count) {
        NSArray *oldEvents = [events filteredArrayUsingPredicate:
                              [NSPredicate predicateWithFormat:
                               @"lastUpdate < %@",
                               [NSDate dateWithTimeIntervalSinceNow:EVENT_TIMEOUT]]];
        
        if (oldEvents.count) {
            [[CoreDataManager sharedManager] deleteObjects:oldEvents];
            
        } else {
            
            NSMutableArray *predTemplates = [NSMutableArray array];
            NSMutableArray *predArguments = [NSMutableArray array];
            
            NSDate *start = [params objectForKey:@"start"];
            if (!start) {
                NSTimeInterval interval = [[params objectForKey:@"time"] doubleValue];
                if (interval) {
                    NSDate *time = [NSDate dateWithTimeIntervalSince1970:interval];
                    if (time) {
                        NSUInteger flags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
                        NSDateComponents *comps = [[NSCalendar currentCalendar] components:flags fromDate:time];
                        start = [[NSCalendar currentCalendar] dateFromComponents:comps];
                    }
                }
            }
            
            if (start) {
                [predTemplates addObject:@"start >= %@"];
                [predArguments addObject:start];
            }
            
            NSDate *end = [params objectForKey:@"end"];
            if (end) {
                [predTemplates addObject:@"end < %@"];
                [predArguments addObject:start];
            }
            
            NSArray *filteredEvents;
            if (predTemplates.count) {
                NSPredicate *pred = [NSPredicate predicateWithFormat:[predTemplates componentsJoinedByString:@" AND "]
                                                       argumentArray:predArguments];
                
                filteredEvents = [events filteredArrayUsingPredicate:pred];
            } else {
                filteredEvents = events;
            }
            
            NSMutableArray *wrappers = [NSMutableArray arrayWithCapacity:filteredEvents.count];
            for (KGOEvent *event in filteredEvents) {
                [wrappers addObject:[[[KGOEventWrapper alloc] initWithKGOEvent:event] autorelease]];
            }
            
            [self.delegate eventsDidChange:wrappers calendar:calendar];
            
            if (wrappers.count) {
                return YES;
            }
        }
    }
    
    if ([[KGORequestManager sharedManager] isReachable]) {
        NSString *requestIdentifier = calendar.identifier;
        KGORequest *request = [_eventsRequests objectForKey:requestIdentifier];
        if (request) {
            [request cancel];
            [_eventsRequests removeObjectForKey:requestIdentifier];
        }
        
        request = [[KGORequestManager sharedManager] requestWithDelegate:self module:self.moduleTag path:@"events" params:params];
        request.expectedResponseType = [NSDictionary class];
        [_eventsRequests setObject:request forKey:requestIdentifier];
        [request connect];
        
        if (request) {
            success = YES;
        }
    }
    
    return success;
}

- (BOOL)requestEventsForCalendar:(KGOCalendar *)calendar time:(NSDate *)time
{
    NSString *timeString = [NSString stringWithFormat:@"%.0f", [time timeIntervalSince1970]];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            calendar.identifier, @"calendar",
                            calendar.type, @"type",
                            timeString, @"time",
                            nil];
    return [self requestEventsForCalendar:calendar params:params];
}


- (BOOL)requestEventsForCalendar:(KGOCalendar *)calendar startDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   calendar.identifier, @"calendar",
                                   calendar.type, @"type",
                                   nil];
    
    if (startDate) {
        NSString *startString = [NSString stringWithFormat:@"%.0f", [startDate timeIntervalSince1970]];
        [params setObject:startString forKey:@"start"];
    }
    
    if (endDate) {
        NSString *endString = [NSString stringWithFormat:@"%.0f", [endDate timeIntervalSince1970]];
        [params setObject:endString forKey:@"end"];
    }
    
    return [self requestEventsForCalendar:calendar params:params];
}

#pragma mark KGORequestDelegate


- (void)requestWillTerminate:(KGORequest *)request
{
    if (request == _groupsRequest) {
        _groupsRequest = nil;
        
    } else { // events
        NSString *category = [request.getParams objectForKey:@"calendar"];
        [_eventsRequests removeObjectForKey:category];
    }
}

/*
// TODO: let delegate know of failure so UI can be adjusted accordingly
- (void)request:(KGORequest *)request didFailWithError:(NSError *)error
{
    [[KGORequestManager sharedManager] showAlertForError:error];
}
*/
- (void)request:(KGORequest *)request didReceiveResult:(id)result
{
    NSLog(@"%@", [result description]);

#pragma mark Request - groups
    if (request == _groupsRequest) {
        
        NSInteger total = [result integerForKey:@"total"];
        NSInteger returned = [result integerForKey:@"returned"];
        if (total > returned) {
            // TODO: implement paging
        }
        
        //NSString *displayField = [result stringForKey:@"displayField" nilIfEmpty:YES];

        NSMutableSet *oldGroupIDs = [NSMutableSet set];
        NSArray *oldGroups = [[CoreDataManager sharedManager] objectsForEntity:KGOEntityNameCalendarGroup matchingPredicate:nil];
        for (KGOCalendarGroup *aGroup in oldGroups) {
            [oldGroupIDs addObject:aGroup.identifier];
        }

        NSArray *groups = [result arrayForKey:@"results"];
        if (returned > groups.count)
            returned = groups.count;

        // TODO: deciding whether groupsDidChange based on just the group ID's
        // will cause the delegate to ignore changes to group titles
        // which isn't fatal but may reflect a delayed state in the UI
        NSMutableArray *newGroups = [NSMutableArray array];
        BOOL groupsDidChange = NO;
        for (NSInteger i = 0; i < returned; i++) {
            NSDictionary *aDict = [groups objectAtIndex:i];
            KGOCalendarGroup *group = [KGOCalendarGroup groupWithDictionary:aDict];
            group.sortOrder = [NSNumber numberWithInt:i];
            [newGroups addObject:group];
            if ([oldGroupIDs containsObject:group.identifier]) {
                [oldGroupIDs removeObject:group.identifier];
            } else {
                groupsDidChange = YES;
            }
        }
        
        for (NSString *oldGroupID in oldGroupIDs) {
            KGOCalendarGroup *group = [KGOCalendarGroup groupWithID:oldGroupID];
            [[CoreDataManager sharedManager] deleteObject:group];
            groupsDidChange = YES;
        }

        if (newGroups.count) {
            [_currentGroup release];
            _currentGroup = [[newGroups objectAtIndex:0] retain];
        }

        if (groupsDidChange) {
            [[CoreDataManager sharedManager] saveData];
            [self.delegate groupsDidChange:newGroups];
        }
        
#pragma mark Request - events
    } else if ([request.path isEqualToString:@"events"]) { // events
        
        NSString *calendarID = [request.getParams objectForKey:@"calendar"];
        KGOCalendar *calendar = [KGOCalendar calendarWithID:calendarID];

        // search results boilerplate
        NSInteger total = [result integerForKey:@"total"];
        NSInteger returned = [result integerForKey:@"returned"];
        if (total > returned) {
            // TODO: implement paging
        }
        
        //NSString *displayField = [result stringForKey:@"displayField" nilIfEmpty:YES];
        
        NSArray *eventDicts = [result arrayForKey:@"results"];
        if (returned > eventDicts.count)
            returned = eventDicts.count;
        
        NSMutableArray *array = [NSMutableArray array];
        for (NSInteger i = 0; i < returned; i++) {
            NSDictionary *aDict = [eventDicts objectAtIndex:i];
            KGOEventWrapper *event = [[[KGOEventWrapper alloc] initWithDictionary:aDict] autorelease];
            [event addCalendar:calendar];
            [array addObject:event];
            [event convertToKGOEvent];
        }
        
        [[CoreDataManager sharedManager] saveData];
        [self.delegate eventsDidChange:array calendar:calendar];
    }
}

- (void)dealloc
{
    [_dateFormatters release];
    
    if (_groupsRequest) {
        [_groupsRequest cancel];
    }
    
    [_categoriesRequests enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [(KGORequest *)obj cancel];
    }];
    [_categoriesRequests release];
     
    [_eventsRequests enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [(KGORequest *)obj cancel];
    }];
    [_eventsRequests release];
    
    [_currentGroup release];
    
    [super dealloc];
}

@end
