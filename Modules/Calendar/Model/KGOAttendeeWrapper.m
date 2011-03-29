#import "KGOAttendeeWrapper.h"
#import <EventKit/EventKit.h>
#import "CalendarModel.h"

@implementation KGOAttendeeWrapper

@synthesize identifier,
name = _name,
attendeeType = _attendeeType,
attendeeStatus = _attendeeStatus;

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        
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
    
    
}

#pragma mark CoreData

- (NSSet *)contactInfo
{
    return _kgoAttendee.contactInfo;
}

- (void)setContactInfo:(NSSet *)contactInfo
{
    if (!_kgoAttendee) {
        _kgoAttendee = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:KGOEntityNameEventAttendee];
        _kgoAttendee.name = self.name;
        _kgoAttendee.identifier = self.identifier;
    }
    
    _kgoAttendee.contactInfo = contactInfo;
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
