#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class KGOEventAttendee;

@interface KGOEventContactInfo : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) KGOEventAttendee * attendee;

@end
