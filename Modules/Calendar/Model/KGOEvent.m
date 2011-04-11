#import "KGOEvent.h"
#import "KGOCalendar.h"
#import "KGOEventParticipantRelation.h"
#import "CoreDataManager.h"

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
@dynamic userInfo;
@dynamic bookmarked;
@dynamic calendars;
@dynamic particpants;

+ (KGOEvent *)eventWithID:(NSString *)identifier
{
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier = %@", identifier];
    KGOEvent *event = [[[CoreDataManager sharedManager] objectsForEntity:KGOEntityNameEvent matchingPredicate:pred] lastObject];
    if (!event) {
        event = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:KGOEntityNameEvent];
        
        event.identifier = identifier;
    }
    return event;
}


- (void)addCalendarsObject:(KGOEventCategory *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"calendars" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"calendars"] addObject:value];
    [self didChangeValueForKey:@"calendars" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeCalendarsObject:(KGOEventCategory *)value {
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


- (void)addParticpantsObject:(KGOEventParticipantRelation *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"particpants" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"particpants"] addObject:value];
    [self didChangeValueForKey:@"particpants" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeParticpantsObject:(KGOEventParticipantRelation *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"particpants" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"particpants"] removeObject:value];
    [self didChangeValueForKey:@"particpants" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addParticpants:(NSSet *)value {    
    [self willChangeValueForKey:@"particpants" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"particpants"] unionSet:value];
    [self didChangeValueForKey:@"particpants" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeParticpants:(NSSet *)value {
    [self willChangeValueForKey:@"particpants" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"particpants"] minusSet:value];
    [self didChangeValueForKey:@"particpants" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


@end
