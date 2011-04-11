#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class KGOEvent, KGOEventParticipant;

@interface KGOEventParticipantRelation : NSManagedObject {
@private
}
@property (nonatomic, retain) NSNumber * isOrganizer;
@property (nonatomic, retain) NSNumber * isAttendee;
@property (nonatomic, retain) KGOEvent * event;
@property (nonatomic, retain) KGOEventParticipant * participant;

+ (KGOEventParticipantRelation *)relationWithEvent:(KGOEvent *)event participant:(KGOEventParticipant *)participant;

@end
