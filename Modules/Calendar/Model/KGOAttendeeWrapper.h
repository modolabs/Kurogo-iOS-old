#import <Foundation/Foundation.h>
#import <EventKit/EKParticipant.h>

// TODO: decide how to use KGOEventParticipantRelation
@class KGOEventParticipant, KGOEventParticipantRelation, KGOEventWrapper;

@interface KGOAttendeeWrapper : NSObject {
    
    EKParticipant *_ekAttendee;
    KGOEventParticipant *_kgoAttendee;
    KGOEventParticipantRelation *_relation;

    NSString *_name;
    EKParticipantType _attendeeType;
    EKParticipantStatus _attendeeStatus;
    
    KGOEventWrapper *_event;
    
}

@property (nonatomic, retain) KGOEventWrapper *event;
@property (nonatomic, retain) KGOEventWrapper *organizedEvent;
@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSSet *contactInfo;
@property (nonatomic) EKParticipantType attendeeType;
@property (nonatomic) EKParticipantStatus attendeeStatus;

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (id)initWithKGOAttendee:(KGOEventParticipant *)attendee;
- (void)convertToKGOAttendee;

@property (nonatomic, retain) EKParticipant *EKAttendee;
@property (nonatomic, retain) KGOEventParticipant *KGOAttendee;

@end
