#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class KGOEvent, KGOCalendar;

@interface KGOCalendarGroup : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * sortOrder;
@property (nonatomic, retain) NSSet* calendars;

+ (KGOCalendarGroup *)groupWithDictionary:(NSDictionary *)aDict;
+ (KGOCalendarGroup *)groupWithID:(NSString *)identifier; // creates entity if not existing
+ (KGOCalendarGroup *)findGroupWithID:(NSString *)identifier; // does not create entity

@end
