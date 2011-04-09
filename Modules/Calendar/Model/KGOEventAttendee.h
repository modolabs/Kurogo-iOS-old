#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class KGOEvent, KGOEventContactInfo;

@interface KGOEventAttendee : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * attendeeType;
@property (nonatomic, retain) KGOEvent * event;
@property (nonatomic, retain) KGOEvent * organizedEvent;
@property (nonatomic, retain) NSSet* contactInfo;

@end
