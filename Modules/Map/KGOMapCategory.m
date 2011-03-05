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
                category.identifier = pathRep;
            }
        } else {
            // TODO handle parse error
        }
    }

    return category;
}

@end
