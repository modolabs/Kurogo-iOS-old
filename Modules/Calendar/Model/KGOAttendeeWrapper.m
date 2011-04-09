#import "KGOAttendeeWrapper.h"
#import <EventKit/EventKit.h>
#import "CalendarModel.h"
#import "Foundation+KGOAdditions.h"

@implementation KGOAttendeeWrapper

@synthesize identifier,
name = _name,
attendeeType = _attendeeType,
attendeeStatus = _attendeeStatus,
event = _event,
organizedEvent;

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.name = [dictionary stringForKey:@"display_name" nilIfEmpty:YES];
        self.identifier = [dictionary stringForKey:@"id" nilIfEmpty:YES];
    }
    return self;
}

#pragma mark EventKit

- (EKParticipant *)EKAttendee
{
    return _ekAttendee;
}

- (void)setEKAttendee:(EKParticipant *)attendee
{
    [_ekAttendee release];
    _ekAttendee = [attendee retain];
    
    self.name = _ekAttendee.name;
    self.attendeeType = _ekAttendee.participantType;
    self.attendeeStatus = _ekAttendee.participantStatus;
}

#pragma mark CoreData

- (id)initWithKGOAttendee:(KGOEventAttendee *)attendee
{
    self = [super init];
    if (self) {
        self.KGOAttendee = attendee;
    }
    return self;
}

- (void)convertToKGOAttendee
{
    if (!_kgoAttendee) {
        _kgoAttendee = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:KGOEntityNameEventAttendee];
        _kgoAttendee.name = self.name;
        _kgoAttendee.identifier = self.identifier;
    }
}

- (NSSet *)contactInfo
{
    [self convertToKGOAttendee];
    return self.KGOAttendee.contactInfo;
}

- (void)setContactInfo:(NSSet *)contactInfo
{
    [self convertToKGOAttendee];
    self.KGOAttendee.contactInfo = contactInfo;
}

- (KGOEventAttendee *)KGOAttendee
{
    return _kgoAttendee;
}

- (void)setKGOAttendee:(KGOEventAttendee *)attendee
{
    [_kgoAttendee release];
    _kgoAttendee = [attendee retain];
    
    self.name = _kgoAttendee.name;
    self.identifier = _kgoAttendee.identifier;
}

@end
