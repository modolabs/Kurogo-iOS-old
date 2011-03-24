#import <Foundation/Foundation.h>
#import <EventKit/EKParticipant.h>

@class KGOEventAttendee;

@interface KGOAttendeeWrapper : NSObject {
    
    EKParticipant *_ekAttendee;
    KGOEventAttendee *_kgoAttendee;

    NSString *_name;
    EKParticipantType _attendeeType;
    EKParticipantStatus _attendeeStatus;
    
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic) EKParticipantType attendeeType;
@property (nonatomic) EKParticipantStatus attendeeStatus;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, retain) EKParticipant *EKAttendee;
@property (nonatomic, retain) KGOEventAttendee *KGOAttendee;

@end
