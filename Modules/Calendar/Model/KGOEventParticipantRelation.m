#import "KGOEventParticipantRelation.h"
#import "KGOEvent.h"
#import "KGOEventParticipant.h"
#import "KGOEventWrapper.h"
#import "KGOAttendeeWrapper.h"
#import "CoreDataManager.h"

@implementation KGOEventParticipantRelation
@dynamic isOrganizer;
@dynamic isAttendee;
@dynamic event;
@dynamic participant;

+ (KGOEventParticipantRelation *)relationWithEvent:(KGOEvent *)event participant:(KGOEventParticipant *)participant
{
    KGOEventParticipantRelation *relation = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:@"KGOEventParticipantRelation"];
    relation.event = event;
    relation.participant = participant;
    return relation;
}

@end
