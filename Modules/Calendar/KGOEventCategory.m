#import "KGOEventCategory.h"
#import "KGOCalendarGroup.h"
#import "KGOEvent.h"
#import "KGOEventCategory.h"
#import "Foundation+KGOAdditions.h"
#import "CoreDataManager.h"

NSString * const KGOEntityNameEventCategory = @"KGOEventCategory";

@implementation KGOEventCategory
@dynamic title;
@dynamic identifier;
@dynamic subCategories;
@dynamic parentCategory;
@dynamic events;
@dynamic group;


+ (KGOEventCategory *)categoryWithID:(NSString *)identifier
{
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier like %@", identifier];
    KGOEventCategory *category = [[[CoreDataManager sharedManager] objectsForEntity:KGOEntityNameEventCategory
                                                               matchingPredicate:pred] lastObject];
    if (!category) {
        category = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:KGOEntityNameEventCategory];
        category.identifier = identifier;
    }
    
    return category;
}


+ (KGOEventCategory *)categoryWithDictionary:(NSDictionary *)aDict
{
    KGOEventCategory *category = nil;
    NSString *identifier = [aDict stringForKey:@"id" nilIfEmpty:YES];
    if (identifier) {
        category = [KGOEventCategory categoryWithID:identifier];
        
        // TODO: fill out
        
    }
    
    return category;
}


#pragma mark - Core data generated accessors

- (void)addSubCategoriesObject:(KGOEventCategory *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"subCategories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"subCategories"] addObject:value];
    [self didChangeValueForKey:@"subCategories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeSubCategoriesObject:(KGOEventCategory *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"subCategories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"subCategories"] removeObject:value];
    [self didChangeValueForKey:@"subCategories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addSubCategories:(NSSet *)value {    
    [self willChangeValueForKey:@"subCategories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"subCategories"] unionSet:value];
    [self didChangeValueForKey:@"subCategories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeSubCategories:(NSSet *)value {
    [self willChangeValueForKey:@"subCategories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"subCategories"] minusSet:value];
    [self didChangeValueForKey:@"subCategories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
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



@end
