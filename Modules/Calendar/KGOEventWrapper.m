#import "KGOEventWrapper.h"
#import <EventKit/EventKit.h>
#import "KGOEvent.h"

@implementation KGOEventWrapper

@synthesize identifier = _identifier,
attendees = _attendees,
endDate = _endDate,
startDate = _startDate,
lastUpdate = _lastUpdate,
allDay = _allDay,
location = _location,
briefLocation = _briefLocation,
title = _title,
summary = _summary,
rrule = _rrule,
organizer = _organizer,
coordinate = _coordinate,
categories = _categories,
contacts = _contacts,
bookmarked = _bookmarked;

+ (EKEventStore *)sharedEventStore
{
    static EKEventStore *s_eventStore = nil;
    if (s_eventStore == nil) {
        s_eventStore = [[EKEventStore alloc] init];
    }
    return s_eventStore;
}


- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (id)initWithEKEvent:(EKEvent *)event
{
    self = [super init];
    if (self) {
        self.EKEvent = event;
    }
    return self;
}

- (EKEvent *)convertToEKEvent
{
    
}

- (BOOL)saveToEventStore
{
}

- (EKEvent *)EKEvent
{
    return _ekEvent;
}

- (void)setEKEvent:(EKEvent *)event
{
    [_ekEvent release];
    _ekEvent = [event retain];
    
    self.identifier = event.eventIdentifier;
    self.endDate = event.endDate;
    self.startDate = event.startDate;
    self.lastUpdate = event.lastModifiedDate;
    self.allDay = event.allDay;
    self.location = event.location;
    self.title = event.title;
    self.summary = event.notes;
    
    // TODO: organizer
    // TODO: attendees
    // TODO: rrule
}

- (id)initWithKGOEvent:(KGOEvent *)event
{
    self = [super init];
    if (self) {
        self.KGOEvent = event;
    }
    return self;
}

- (KGOEvent *)convertToKGOEvent
{
    
}

- (void)saveToCoreData
{
}

- (void)bookmark
{
}

- (void)unbookmark
{
}

- (KGOEvent *)KGOEvent
{
    return _kgoEvent;
}

- (void)setKGOEvent:(KGOEvent *)event
{
    [_kgoEvent release];
    _kgoEvent = [event retain];
    
    self.identifier = event.identifier;
    
}

@end
