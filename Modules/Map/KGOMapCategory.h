#import <CoreData/CoreData.h>
#import "KGOSearchModel.h"

@class KGOPlacemark;

@interface KGOMapCategory : NSManagedObject <KGOCategory>
{
}

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSNumber * sortOrder;
@property (nonatomic, retain) NSSet* places;
@property (nonatomic, retain) NSSet* subcategories;
@property (nonatomic, retain) KGOMapCategory * parentCategory;

@end


@interface KGOMapCategory (CoreDataGeneratedAccessors)
- (void)addPlacesObject:(KGOPlacemark *)value;
- (void)removePlacesObject:(KGOPlacemark *)value;
- (void)addPlaces:(NSSet *)value;
- (void)removePlaces:(NSSet *)value;

@end

