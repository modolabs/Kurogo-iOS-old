#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class KGOCalendarGroup, KGOEvent, KGOEventCategory;

@interface KGOEventCategory : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSSet* subCategories;
@property (nonatomic, retain) KGOEventCategory * parentCategory;
@property (nonatomic, retain) NSSet* events;
@property (nonatomic, retain) KGOCalendarGroup * group;

+ (KGOEventCategory *)categoryWithID:(NSString *)identifier;
+ (KGOEventCategory *)categoryWithDictionary:(NSDictionary *)aDict;

@end
