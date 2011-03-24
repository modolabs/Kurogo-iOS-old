#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class KGOEvent, KGOEventCategory;

@interface KGOCalendarGroup : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * sortOrder;
@property (nonatomic, retain) NSSet* categories;

+ (KGOCalendarGroup *)groupWithDictionary:(NSDictionary *)aDict;
+ (KGOCalendarGroup *)groupWithID:(NSString *)identifier;

@end
