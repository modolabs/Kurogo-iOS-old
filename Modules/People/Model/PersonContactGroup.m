#import "PersonContactGroup.h"
#import "PersonContact.h"
#import "Foundation+KGOAdditions.h"
#import "CoreDataManager.h"

NSString * const PersonContactGroupEntityName = @"PersonContactGroup";

@implementation PersonContactGroup
@dynamic identifier;
@dynamic title;
@dynamic sortOrder;
@dynamic contacts;

- (NSArray *)items
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES];
    return [self.contacts sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
}

- (id<KGOCategory>)parent
{
    return nil;
}

- (NSArray *)children
{
    return nil;
}

+ (PersonContactGroup *)contactGroupWithDict:(NSDictionary *)dict
{
    PersonContactGroup *group = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:PersonContactGroupEntityName];
    group.title = [dict nonemptyStringForKey:@"title"];
    group.identifier = [dict nonemptyStringForKey:@"group"];
    return group;
}

+ (PersonContactGroup *)contactGroupWithID:(NSString *)groupID
{
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier = %@", groupID];
    NSArray *matches = [[CoreDataManager sharedManager] objectsForEntity:PersonContactGroupEntityName
                                                       matchingPredicate:pred];
    if (matches.count) {
        return [matches lastObject];
    }
    return nil;
}

- (void)addContactsObject:(PersonContact *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"contacts" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"contacts"] addObject:value];
    [self didChangeValueForKey:@"contacts" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeContactsObject:(PersonContact *)value {
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
