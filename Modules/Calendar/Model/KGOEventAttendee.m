#import "KGOEventAttendee.h"
#import "KGOEvent.h"
#import "KGOEventContactInfo.h"

NSString * const KGOEntityNameEventAttendee = @"KGOEventAttendee";

@implementation KGOEventAttendee
@dynamic name;
@dynamic identifier;
@dynamic attendeeType;
@dynamic event;
@dynamic contactInfo;
@dynamic organizedEvent;

- (void)addContactInfoObject:(KGOEventContactInfo *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"contactInfo" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"contactInfo"] addObject:value];
    [self didChangeValueForKey:@"contactInfo" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeContactInfoObject:(KGOEventContactInfo *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"contactInfo" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"contactInfo"] removeObject:value];
    [self didChangeValueForKey:@"contactInfo" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addContactInfo:(NSSet *)value {    
    [self willChangeValueForKey:@"contactInfo" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"contactInfo"] unionSet:value];
    [self didChangeValueForKey:@"contactInfo" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeContactInfo:(NSSet *)value {
    [self willChangeValueForKey:@"contactInfo" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"contactInfo"] minusSet:value];
    [self didChangeValueForKey:@"contactInfo" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


@end
