#import "KGOMapCategory.h"
#import "KGOPlacemark.h"
#import "Foundation+KGOAdditions.h"
#import "CoreDataManager.h"

@implementation KGOMapCategory

@dynamic title;
@dynamic identifier;
@dynamic sortOrder;
@dynamic places;
@dynamic subcategories;
@dynamic parentCategory;

- (NSArray *)items {
	return [self.places allObjects];
}

- (KGOMapCategory *)parent {
	return self.parentCategory;
}

- (NSArray *)children {
	return [self.subcategories allObjects];
}

+ (KGOMapCategory *)categoryWithPath:(NSArray *)categoryPath {
    if (!categoryPath.count) {
        return nil;
    }
    
    NSMutableString *pathRep = [NSMutableString string];
    KGOMapCategory *parentCategory = nil;
    KGOMapCategory *category = nil;
    
    for (id component in categoryPath) {
        if ([component isKindOfClass:[NSString class]] || [component isKindOfClass:[NSNumber class]]) {
            if (pathRep.length) {
                [pathRep appendString:[NSString stringWithFormat:@"/%@", component]];
            } else {
                [pathRep appendString:[component description]];
            }
            
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier like %@", pathRep];
            category = [[[CoreDataManager sharedManager] objectsForEntity:MapCategoryEntityName matchingPredicate:pred] lastObject];
            if (!category) {
                category = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:MapCategoryEntityName];
                category.identifier = [NSString stringWithString:pathRep]; // pathRep is mutatable so make a copy
                category.parentCategory = parentCategory;
                //[[CoreDataManager sharedManager] saveData];
                DLog(@"created new category with id %@, parent id: %@", category.identifier, category.parentCategory.identifier);
            } else {
                DLog(@"found category with identifier %@", category.identifier);
            }

            parentCategory = category;
        } else {
            // TODO handle parse error
            NSLog(@"unable to deal with path component %@", [component description]);
        }
    }
    
    return category;
}

- (void)addSubcategoriesObject:(KGOMapCategory *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"subcategories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"subcategories"] addObject:value];
    [self didChangeValueForKey:@"subcategories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeSubcategoriesObject:(KGOMapCategory *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"subcategories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"subcategories"] removeObject:value];
    [self didChangeValueForKey:@"subcategories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addSubcategories:(NSSet *)value {    
    [self willChangeValueForKey:@"subcategories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"subcategories"] unionSet:value];
    [self didChangeValueForKey:@"subcategories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeSubcategories:(NSSet *)value {
    [self willChangeValueForKey:@"subcategories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"subcategories"] minusSet:value];
    [self didChangeValueForKey:@"subcategories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


- (void)addPlacesObject:(KGOPlacemark *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"places" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"places"] addObject:value];
    [self didChangeValueForKey:@"places" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removePlacesObject:(KGOPlacemark *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"places" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"places"] removeObject:value];
    [self didChangeValueForKey:@"places" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addPlaces:(NSSet *)value {    
    [self willChangeValueForKey:@"places" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"places"] unionSet:value];
    [self didChangeValueForKey:@"places" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removePlaces:(NSSet *)value {
    [self willChangeValueForKey:@"places" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"places"] minusSet:value];
    [self didChangeValueForKey:@"places" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}



@end
