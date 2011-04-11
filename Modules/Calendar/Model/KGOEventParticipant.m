#import "KGOEventParticipant.h"
#import "KGOEventContactInfo.h"
#import "KGOEventParticipantRelation.h"

NSString * const KGOEntityNameEventAttendee = @"KGOEventParticipant";

@implementation KGOEventParticipant
@dynamic attendeeType;
@dynamic identifier;
@dynamic name;
@dynamic contactInfo;
@dynamic events;

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
