#import "EmergencyContactsSection.h"
#import "EmergencyContact.h"

NSString * const EmergencyContactsSectionEntityName = @"EmergencyContactsSection";

@implementation EmergencyContactsSection
@dynamic moduleTag;
@dynamic sectionTag;
@dynamic lastUpdate;
@dynamic contacts;

- (void)addContactsObject:(EmergencyContact *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"contacts" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"contacts"] addObject:value];
    [self didChangeValueForKey:@"contacts" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeContactsObject:(EmergencyContact *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"contacts" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"contacts"] removeObject:value];
    [self didChangeValueForKey:@"contacts" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addContacts:(NSSet *)value {    
    [self willChangeValueForKey:@"contacts" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"contacts"] unionSet:value];
    [self didChangeValueForKey:@"contacts" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeContacts:(NSSet *)value {
    [self willChangeValueForKey:@"contacts" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"contacts"] minusSet:value];
    [self didChangeValueForKey:@"contacts" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


@end
