#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "KGOSearchModel.h"

@class KGOCalendarGroup, KGOEvent;

@interface KGOCalendar : NSManagedObject <KGOCategory> {
@private
}
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSSet* subCalendars;
@property (nonatomic, retain) KGOCalendar * parentCalendar;
@property (nonatomic, retain) NSSet* events;
@property (nonatomic, retain) NSSet* groups;

+ (KGOCalendar *)calendarWithID:(NSString *)identifier;
+ (KGOCalendar *)calendarWithDictionary:(NSDictionary *)aDict;

@end
