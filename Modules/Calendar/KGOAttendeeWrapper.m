#import "KGOAttendeeWrapper.h"
#import <EventKit/EventKit.h>
#import "KGOEventAttendee.h"

@implementation KGOAttendeeWrapper

@synthesize name = _name,
attendeeType = _attendeeType,
attendeeStatus = _attendeeStatus;

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (EKParticipant *)EKAttendee
{
    return _ekAttendee;
}

- (void)setEKAttendee:(EKParticipant *)attendee
{
    [_ekAttendee release];
    _ekAttendee = [attendee retain];
    
    
}

- (KGOEventAttendee *)KGOAttendee
{
    return _kgoAttendee;
}

- (void)setKGOAttendee:(KGOEventAttendee *)attendee
{
    [_kgoAttendee release];
    _kgoAttendee = [attendee retain];



}

@end
