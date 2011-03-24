#import "KGOEvent.h"
#import "KGOCalendarGroup.h"
#import "KGOEventAttendee.h"
#import "KGOCalendar.h"

NSString * const KGOEntityNameEvent = @"KGOEvent";

@implementation KGOEvent
@dynamic start;
@dynamic lastUpdate;
@dynamic rrule;
@dynamic longitude;
@dynamic briefLocation;
@dynamic latitude;
@dynamic title;
@dynamic identifier;
@dynamic location;
@dynamic summary;
@dynamic end;
@dynamic calendars;
@dynamic attendees;
@dynamic organizer;

#pragma mark - Core data generated methods

- (void)addCalendarsObject:(KGOCalendar *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"calendars" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"calendars"] addObject:value];
    [self didChangeValueForKey:@"calendars" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeCalendarsObject:(KGOCalendar *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"calendars" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"calendars"] removeObject:value];
    [self didChangeValueForKey:@"calendars" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addCalendars:(NSSet *)value {    
    [self willChangeValueForKey:@"calendars" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"calendars"] unionSet:value];
    [self didChangeValueForKey:@"calendars" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeCalendars:(NSSet *)value {
    [self willChangeValueForKey:@"calendars" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"calendars"] minusSet:value];
    [self didChangeValueForKey:@"calendars" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


- (void)addAttendeesObject:(KGOEventAttendee *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"attendees" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"attendees"] addObject:value];
    [self didChangeValueForKey:@"attendees" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeAttendeesObject:(KGOEventAttendee *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"attendees" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"attendees"] removeObject:value];
    [self didChangeValueForKey:@"attendees" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addAttendees:(NSSet *)value {    
    [self willChangeValueForKey:@"attendees" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"attendees"] unionSet:value];
    [self didChangeValueForKey:@"attendees" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeAttendees:(NSSet *)value {
    [self willChangeValueForKey:@"attendees" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"attendees"] minusSet:value];
    [self didChangeValueForKey:@"attendees" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}




@end
