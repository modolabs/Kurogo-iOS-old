#import "KGOCalendar.h"
#import "KGOCalendarGroup.h"
#import "KGOEvent.h"
#import "Foundation+KGOAdditions.h"
#import "CoreDataManager.h"

NSString * const KGOEntityNameEventCategory = @"KGOCalendar";

@implementation KGOCalendar
@dynamic title;
@dynamic identifier;
@dynamic type;
@dynamic subCalendars;
@dynamic parentCalendar;
@dynamic events;
@dynamic groups;

+ (KGOCalendar *)categoryWithID:(NSString *)identifier
{
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier like %@", identifier];
    KGOCalendar *category = [[[CoreDataManager sharedManager] objectsForEntity:KGOEntityNameEventCategory
                                                               matchingPredicate:pred] lastObject];
    if (!category) {
        category = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:KGOEntityNameEventCategory];
        category.identifier = identifier;
    }
    
    return category;
}


+ (KGOCalendar *)categoryWithDictionary:(NSDictionary *)aDict
{
    KGOCalendar *category = nil;
    NSString *identifier = [aDict stringForKey:@"id" nilIfEmpty:YES];
    if (identifier) {
        category = [KGOCalendar categoryWithID:identifier];
        
        // TODO: fill out
        
    }
    
    return category;
}


#pragma mark KGOCategory

- (id<KGOCategory>)parent
{
    return self.parentCalendar;
}

- (NSArray *)children
{
    // TODO: sort
    return [self.subCalendars allObjects];
}

- (NSArray *)items
{
    // TODO: refine
    return [self.events allObjects];
}

#pragma mark - Core data generated accessors

- (void)addSubCategoriesObject:(KGOCalendar *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"subCalendars" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"subCalendars"] addObject:value];
    [self didChangeValueForKey:@"subCalendars" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeSubCategoriesObject:(KGOCalendar *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"subCalendars" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"subCalendars"] removeObject:value];
    [self didChangeValueForKey:@"subCalendars" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addSubCategories:(NSSet *)value {    
    [self willChangeValueForKey:@"subCalendars" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"subCalendars"] unionSet:value];
    [self didChangeValueForKey:@"subCalendars" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeSubCategories:(NSSet *)value {
    [self willChangeValueForKey:@"subCalendars" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"subCalendars"] minusSet:value];
    [self didChangeValueForKey:@"subCalendars" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}



- (void)addEventsObject:(KGOEvent *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"events" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"events"] addObject:value];
    [self didChangeValueForKey:@"events" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeEventsObject:(KGOEvent *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"events" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"events"] removeObject:value];
    [self didChangeValueForKey:@"events" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addEvents:(NSSet *)value {    
    [self willChangeValueForKey:@"events" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"events"] unionSet:value];
    [self didChangeValueForKey:@"events" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeEvents:(NSSet *)value {
    [self willChangeValueForKey:@"events" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"events"] minusSet:value];
    [self didChangeValueForKey:@"events" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}



- (void)addGroupsObject:(KGOEvent *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"groups" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"groups"] addObject:value];
    [self didChangeValueForKey:@"groups" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeGroupsObject:(KGOEvent *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"groups" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"groups"] removeObject:value];
    [self didChangeValueForKey:@"groups" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addGroups:(NSSet *)value {    
    [self willChangeValueForKey:@"groups" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"groups"] unionSet:value];
    [self didChangeValueForKey:@"groups" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeGroups:(NSSet *)value {
    [self willChangeValueForKey:@"groups" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"groups"] minusSet:value];
    [self didChangeValueForKey:@"groups" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


@end
