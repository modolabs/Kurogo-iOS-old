#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class KGOCalendar, KGOEventAttendee;

@interface KGOEvent : NSManagedObject {
@private
}
@property (nonatomic, retain) NSDate * start;
@property (nonatomic, retain) NSDate * lastUpdate;
@property (nonatomic, retain) NSString * rrule;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * briefLocation;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSDate * end;
@property (nonatomic, retain) NSSet* calendars;
@property (nonatomic, retain) NSSet* attendees;
@property (nonatomic, retain) KGOEventAttendee * organizer;

@end
