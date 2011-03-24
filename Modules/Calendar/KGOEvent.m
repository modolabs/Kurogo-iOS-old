#import "KGOEvent.h"
#import "KGOCalendarGroup.h"
#import "KGOEventAttendee.h"
#import "KGOEventCategory.h"

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
@dynamic categories;
@dynamic attendees;
@dynamic organizer;
@dynamic calendar;

- (void)addCategoriesObject:(KGOEventCategory *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"categories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"categories"] addObject:value];
    [self didChangeValueForKey:@"categories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeCategoriesObject:(KGOEventCategory *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"categories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"categories"] removeObject:value];
    [self didChangeValueForKey:@"categories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addCategories:(NSSet *)value {    
    [self willChangeValueForKey:@"categories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"categories"] unionSet:value];
    [self didChangeValueForKey:@"categories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeCategories:(NSSet *)value {
    [self willChangeValueForKey:@"categories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"categories"] minusSet:value];
    [self didChangeValueForKey:@"categories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
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
