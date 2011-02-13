#import <CoreData/CoreData.h>

@class KGOEvent;

@interface KGOEventCategory :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSSet* subCategories;
@property (nonatomic, retain) KGOEventCategory * parentCategory;
@property (nonatomic, retain) NSSet* events;

@end


@interface KGOEventCategory (CoreDataGeneratedAccessors)
- (void)addSubCategoriesObject:(KGOEventCategory *)value;
- (void)removeSubCategoriesObject:(KGOEventCategory *)value;
- (void)addSubCategories:(NSSet *)value;
- (void)removeSubCategories:(NSSet *)value;

- (void)addEventsObject:(KGOEvent *)value;
- (void)removeEventsObject:(KGOEvent *)value;
- (void)addEvents:(NSSet *)value;
- (void)removeEvents:(NSSet *)value;

@end

