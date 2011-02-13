#import <Foundation/Foundation.h>
#import "CalendarModel.h"
#import "CalendarConstants.h"

@interface CalendarDataManager : NSObject {

}

+ (NSArray *)eventsWithStartDate:(NSDate *)startDate listType:(CalendarEventListType)listType category:(NSNumber *)catID;
+ (NSNumber *)idForCategory:(NSString *)categoryName;

+ (NSArray *)topLevelCategories;
+ (KGOEventCategory *)categoryWithID:(NSInteger)catID;
+ (KGOEvent *)eventWithID:(NSInteger)eventID;
+ (KGOEvent *)eventWithDict:(NSDictionary *)dict;
+ (KGOEventCategory *)categoryWithDict:(NSDictionary *)dict;
+ (void)pruneOldEvents;

@end
