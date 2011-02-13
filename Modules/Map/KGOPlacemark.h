#import <CoreData/CoreData.h>
#import "KGOSearchModel.h"

@class KGOMapCategory;

@interface KGOPlacemark : NSManagedObject <KGOSearchResult>
{
}

@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * street;
@property (nonatomic, retain) NSString * geometryType;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSData * geometry;
@property (nonatomic, retain) NSString * info;
@property (nonatomic, retain) NSNumber * sortOrder;
@property (nonatomic, retain) NSData * photo;
@property (nonatomic, retain) NSNumber * bookmarked;
@property (nonatomic, retain) NSSet* categories;
@property (nonatomic, retain) KGOPlacemark * parent;
@property (nonatomic, retain) NSSet* children;

@end


@interface KGOPlacemark (CoreDataGeneratedAccessors)
- (void)addCategoriesObject:(KGOMapCategory *)value;
- (void)removeCategoriesObject:(KGOMapCategory *)value;
- (void)addCategories:(NSSet *)value;
- (void)removeCategories:(NSSet *)value;

- (void)addChildrenObject:(KGOPlacemark *)value;
- (void)removeChildrenObject:(KGOPlacemark *)value;
- (void)addChildren:(NSSet *)value;
- (void)removeChildren:(NSSet *)value;

@end

