#import "CalendarDataManager.h"
#import "CoreDataManager.h"
#import "Foundation+KGOAdditions.h"
#import "CalendarModel.h"

@implementation CalendarDataManager

@synthesize delegate;

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

- (void)requestGroups
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES];
    NSArray *oldGroups = [[CoreDataManager sharedManager] objectsForEntity:KGOEntityNameCalendarGroup
                                                         matchingPredicate:nil
                                                           sortDescriptors:[NSArray arrayWithObject:sort]];
    
    if (oldGroups) {
        [self.delegate groupsDidChange:oldGroups];
        // TODO: use a timeout value to decide whether or not to refresh
        return;
    }
    
    
    if(_groupsRequest) {
        return;
    }
    
    _groupsRequest = [[KGORequestManager sharedManager] requestWithDelegate:self module:@"calendar" path:@"groups" params:nil];
    _groupsRequest.expectedResponseType = [NSDictionary class];
    [_groupsRequest connect];
}

- (void)requestCategoriesForGroup:(NSString *)group
{
    KGORequest *request = [_categoriesRequests objectForKey:group];
    
    if (request) {
        return;
    }
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:group, @"category", nil];
    request = [[KGORequestManager sharedManager] requestWithDelegate:self module:@"calendar" path:@"categories" params:params];
    request.expectedResponseType = [NSArray class];
    [_categoriesRequests setObject:request forKey:group];
    [request connect];
}

- (void)requestEventsForCategory:(NSString *)category startDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
    KGORequest *request = [_eventsRequests objectForKey:category];
    if (request) {
        [request cancel];
        [_eventsRequests removeObjectForKey:category];
    }
    
    NSString *startString = [NSString stringWithFormat:@"%.0f", [startDate timeIntervalSince1970]];
    NSString *endString = [NSString stringWithFormat:@"%.0f", [endDate timeIntervalSince1970]];
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            startString, @"start",
                            endString, @"end",
                            nil];

    request = [[KGORequestManager sharedManager] requestWithDelegate:self module:@"calendar" path:@"events" params:params];
    request.expectedResponseType = [NSDictionary class];
    [_eventsRequests setObject:request forKey:category];
    [request connect];
}

#pragma mark KGORequestDelegate


- (void)requestWillTerminate:(KGORequest *)request
{
    if (request == _groupsRequest) {
        _groupsRequest = nil;
        
    } else if ([request.path isEqualToString:@"categories"]) {
        NSString *group = [request.getParams objectForKey:@"category"];
        [_categoriesRequests removeObjectForKey:group];
        
    } else { // events
        NSString *category = [request.getParams objectForKey:@"category"];
        [_eventsRequests removeObjectForKey:category];
    }
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result
{
    NSLog(@"%@", [result description]);
    
    if (request == _groupsRequest) {
        _groupsRequest = nil;
        
        //NSInteger total = [result integerForKey:@"total"];
        NSInteger returned = [result integerForKey:@"returned"];
        //NSString *displayField = [result stringForKey:@"displayField" nilIfEmpty:YES];

        NSMutableSet *oldGroupIDs = [NSMutableSet set];
        NSArray *oldGroups = [[CoreDataManager sharedManager] objectsForEntity:KGOEntityNameCalendarGroup matchingPredicate:nil];
        for (KGOCalendarGroup *aGroup in oldGroups) {
            [oldGroupIDs addObject:aGroup.identifier];
        }

        NSArray *groups = [result arrayForKey:@"results"];
        if (returned > groups.count)
            returned = groups.count;
        
        NSMutableArray *newGroups = [NSMutableArray array];
        for (NSInteger i = 0; i < returned; i++) {
            NSDictionary *aDict = [groups objectAtIndex:i];
            KGOCalendarGroup *group = [KGOCalendarGroup groupWithDictionary:aDict];
            group.sortOrder = [NSNumber numberWithInt:i];
            [newGroups addObject:group];
            [oldGroupIDs removeObject:group.identifier];
        }
        
        for (NSString *oldGroupID in oldGroupIDs) {
            KGOCalendarGroup *group = [KGOCalendarGroup groupWithID:oldGroupID];
            [[CoreDataManager sharedManager] deleteObject:group];
        }

        if (newGroups.count) {
            [_currentGroup release];
            _currentGroup = [[newGroups objectAtIndex:0] retain];
        }
        
        [[CoreDataManager sharedManager] saveData];
        
        [self.delegate groupsDidChange:newGroups];
        
        
    } else if ([request.path isEqualToString:@"categories"]) {
        NSString *group = [request.getParams objectForKey:@"category"];
        [_categoriesRequests removeObjectForKey:group];
        
        
    } else { // events
        NSString *category = [request.getParams objectForKey:@"category"];
        [_eventsRequests removeObjectForKey:category];
        
        
    }
}

@end
