#import "KGOMapCategory.h"
#import "KGOPlacemark.h"
#import "Foundation+KGOAdditions.h"
#import "CoreDataManager.h"

NSString * const MapCategoryEntityName = @"KGOMapCategory";

@implementation KGOMapCategory

@dynamic title;
@dynamic identifier;
@dynamic sortOrder;
@dynamic places;
@dynamic subcategories;
@dynamic parentCategory;
@dynamic latitude;
@dynamic longitude;
@dynamic subtitle;

@synthesize moduleTag;

- (NSArray *)items {
	return [self.places allObjects];
}

- (KGOMapCategory *)parent {
	return self.parentCategory;
}

- (NSArray *)children {
	return [self.subcategories allObjects];
}

+ (KGOMapCategory *)categoryWithIdentifier:(NSString *)categoryID
{
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier like %@", categoryID];
    NSArray *results = [[CoreDataManager sharedManager] objectsForEntity:MapCategoryEntityName matchingPredicate:pred];
    if (results.count > 1) {
        DLog(@"Warning: multiple category objects found for id %@", categoryID);
    }
    KGOMapCategory *category = [results lastObject];
    if (!category) {
        category = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:MapCategoryEntityName];
        category.identifier = categoryID;
        DLog(@"created new category with id %@", category.identifier);
    }
    return category;
}

+ (KGOMapCategory *)categoryWithDictionary:(NSDictionary *)dictionary
{
    KGOMapCategory *category = nil;
    
    NSString *identifier = [dictionary nonemptyStringForKey:@"id"];
    if (identifier) {
        category = [KGOMapCategory categoryWithIdentifier:identifier];
        NSString *title = [dictionary nonemptyStringForKey:@"title"];
        if (title) {
            category.title = title;
        }
        NSString *subtitle = [dictionary nonemptyStringForKey:@"subtitle"];
        if (subtitle) {
            category.subtitle = subtitle;
        }
        CGFloat lat = [dictionary floatForKey:@"lat"];
        if (lat) {
            category.latitude = [NSNumber numberWithFloat:lat];
        }
        CGFloat lon = [dictionary floatForKey:@"lon"];
        if (lat) {
            category.longitude = [NSNumber numberWithFloat:lon];
        }
        NSString *group = [dictionary nonemptyStringForKey:@"group"];
        if (group) {
            category.parentCategory = [KGOMapCategory categoryWithIdentifier:group];
        }
    }
    return category;
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
                DLog(@"created new category with id %@, parent id: %@", category.identifier, category.parentCategory.identifier);
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
