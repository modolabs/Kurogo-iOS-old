#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class KGOEventContactInfo, KGOEventParticipantRelation;

@interface KGOEventParticipant : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * attendeeType;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet* contactInfo;
@property (nonatomic, retain) NSSet* events;

@end
