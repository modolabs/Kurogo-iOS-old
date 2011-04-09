#import "KGOEventWrapper.h"
#import <EventKit/EventKit.h>
#import "CalendarModel.h"
#import "Foundation+KGOAdditions.h"
#import "UIKit+KGOAdditions.h"

@implementation KGOEventWrapper

@synthesize identifier = _identifier,
//attendees = _attendees,
endDate = _endDate,
startDate = _startDate,
lastUpdate = _lastUpdate,
allDay = _allDay,
location = _location,
briefLocation = _briefLocation,
title = _title,
summary = _summary,
rrule = _rrule,
//organizers = _organizers,
coordinate = _coordinate,
calendars = _calendars,
bookmarked = _bookmarked, 
userInfo = _userInfo;

#pragma mark KGOSearchResult

- (UIImage *)annotationImage
{
    return [UIImage imageWithPathName:@"modules/calendar/event_map_pin"];
}


#pragma mark -

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
    NSString *identifier = [dictionary stringForKey:@"id" nilIfEmpty:YES];
    if (!identifier) {
        [self release];
        return nil;
    }
    
    self = [super init];
    if (self) {
        self.identifier = identifier;
        
        KGOEvent *storedEvent = [KGOEvent eventWithID:self.identifier];
        if (storedEvent) {
            self.KGOEvent = storedEvent;
        }
        
        [self updateWithDictionary:dictionary];        
    }
    return self;
}

- (void)updateWithDictionary:(NSDictionary *)dictionary
{
    // basic info
    self.title = [dictionary stringForKey:@"title" nilIfEmpty:YES];
    if (!self.title) {
        // TODO: deprecate this from API
        self.title = [dictionary stringForKey:@"summary" nilIfEmpty:YES];
    }
    self.summary = [dictionary stringForKey:@"description" nilIfEmpty:YES];
    
    // time
    NSTimeInterval startTimestamp = [dictionary floatForKey:@"start"];
    if (startTimestamp) {
        self.startDate = [NSDate dateWithTimeIntervalSince1970:startTimestamp];
    }
    NSTimeInterval endTimestamp = [dictionary floatForKey:@"end"];
    if (endTimestamp) {
        self.endDate = [NSDate dateWithTimeIntervalSince1970:endTimestamp];
    }
    NSNumber *allDay = [dictionary objectForKey:@"allday"];
    if (allDay && [allDay isKindOfClass:[NSNumber class]]) {
        self.allDay = [allDay boolValue];
    } else {
        self.allDay = (endTimestamp - startTimestamp) + 1 >= 24 * 60 * 60;
    }
    
    // location
    self.location = [dictionary stringForKey:@"location" nilIfEmpty:YES];
    
    // TODO: contact info
    
    
    self.lastUpdate = [NSDate date];
}

#pragma mark eventkit

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
    [_ekEvent release];
    _ekEvent = [[KGOEventWrapper sharedEventStore] eventWithIdentifier:self.identifier];
    _ekEvent.location = self.location;
    _ekEvent.title = self.title;
    _ekEvent.endDate = self.endDate;
    _ekEvent.startDate = self.startDate;
    _ekEvent.notes = self.summary;
    _ekEvent.allDay = self.allDay;
    // TODO: complete this
    
    return _ekEvent;
}

- (BOOL)saveToEventStore
{
    NSError *error = nil;
    // TODO: determine whether to use EKSpanThisEvent or EKSpanFutureEvents
    return [[KGOEventWrapper sharedEventStore] saveEvent:_ekEvent span:EKSpanThisEvent error:&error];
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

#pragma mark - core data

- (id)initWithKGOEvent:(KGOEvent *)event
{
    self = [super init];
    if (self) {
        self.KGOEvent = event;
    }
    return self;
}

- (NSSet *)organizers
{
    return _organizers;
}

- (void)setOrganizers:(NSSet *)organizers
{
    [_organizers release];
    _organizers = [organizers retain];
    
    NSSet *unwrapperOrganizers = [self unwrappedOrganizers];
    if (unwrapperOrganizers.count) {
        if (!_kgoEvent) {
            [self convertToKGOEvent];
        } else {
            _kgoEvent.organizers = unwrapperOrganizers;
        }
        
    } else if (_kgoEvent) {
        for (KGOAttendeeWrapper *wrapper in _organizers) {
            [wrapper convertToKGOAttendee];
            KGOEventAttendee *attendee = [wrapper KGOAttendee];
            attendee.organizedEvent = _kgoEvent;
        }
    }
}

- (NSSet *)unwrappedOrganizers
{
    if (!self.organizers.count)
        return nil;
    
    NSMutableSet *set = [NSMutableSet set];
    for (KGOAttendeeWrapper *wrapper in self.organizers) {
        KGOEventAttendee *attendee = [wrapper KGOAttendee];
        if (attendee) {
            [set addObject:attendee];
        }
    }
    NSLog(@"unwrapped organizers: %@", set);
    return set;
}

- (NSSet *)attendees
{
    return _attendees;
}

- (void)setAttendees:(NSSet *)attendees
{
    [_attendees release];
    _attendees = [attendees retain];
    
    NSSet *unwrappedAttendees = [self unwrappedAttendees];
    if (unwrappedAttendees.count) {
        if (!_kgoEvent) {
            [self convertToKGOEvent];
        } else {
            _kgoEvent.attendees = unwrappedAttendees;
        }
        
    } else if (_kgoEvent) {
        for (KGOAttendeeWrapper *wrapper in _attendees) {
            [wrapper convertToKGOAttendee];
            KGOEventAttendee *attendee = [wrapper KGOAttendee];
            attendee.event = _kgoEvent;
        }
    }
}

- (NSSet *)unwrappedAttendees
{
    if (!self.attendees.count)
        return nil;
    
    NSMutableSet *set = [NSMutableSet set];
    for (KGOAttendeeWrapper *wrapper in self.attendees) {
        KGOEventAttendee *attendee = [wrapper KGOAttendee];
        if (attendee) {
            [set addObject:attendee];
        }
    }
    NSLog(@"unwrapped attendees: %@", set);
    return set;
}

- (KGOEvent *)convertToKGOEvent
{
    if (!_kgoEvent) {
        _kgoEvent = [[KGOEvent eventWithID:self.identifier] retain];
        _kgoEvent.title = self.title;
        _kgoEvent.location = self.location;
        _kgoEvent.briefLocation = self.briefLocation;
        _kgoEvent.start = self.startDate;
        _kgoEvent.end = self.endDate;
        _kgoEvent.latitude = [NSNumber numberWithFloat:self.coordinate.latitude];
        _kgoEvent.longitude = [NSNumber numberWithFloat:self.coordinate.longitude];
        _kgoEvent.summary = self.summary;
        _kgoEvent.organizers = [self unwrappedOrganizers];
        _kgoEvent.attendees = [self unwrappedAttendees];
        _kgoEvent.lastUpdate = [NSDate date];
        
        if (_userInfo) {
            _kgoEvent.userInfo = [NSKeyedArchiver archivedDataWithRootObject:_userInfo];
        }
    }
    return _kgoEvent;
}

- (void)addCalendar:(KGOCalendar *)aCalendar
{
    if (!_calendars) {
        _calendars = [[NSMutableSet alloc] init];
    }
    [_calendars addObject:aCalendar];
}

- (void)saveToCoreData
{
    [self convertToKGOEvent];
    [[CoreDataManager sharedManager] saveData];
}

- (BOOL)isBookmarked
{
    return [self.KGOEvent.bookmarked boolValue];
}

- (void)addBookmark
{
    if (!self.KGOEvent) {
        [self convertToKGOEvent];
    }
    self.KGOEvent.bookmarked = [NSNumber numberWithBool:YES];
}

- (void)removeBookmark
{
    if (self.KGOEvent) {
        self.KGOEvent.bookmarked = [NSNumber numberWithBool:NO];
    }
}

- (KGOEvent *)KGOEvent
{
    return _kgoEvent;
}

- (void)setKGOEvent:(KGOEvent *)event
{
    [_kgoEvent release];
    _kgoEvent = [event retain];

    if (!self.identifier)    self.identifier    = _kgoEvent.identifier;
    if (!self.title)         self.title         = _kgoEvent.title;
    if (!self.location)      self.location      = _kgoEvent.location;
    if (!self.briefLocation) self.briefLocation = _kgoEvent.briefLocation;
    if (!self.startDate)     self.startDate     = _kgoEvent.start;
    if (!self.endDate)       self.endDate       = _kgoEvent.end;
    if (!self.summary)       self.summary       = _kgoEvent.summary;
    if (!self.calendars)     self.calendars     = _kgoEvent.calendars;
    if (!self.rrule)         self.rrule         = [NSKeyedUnarchiver unarchiveObjectWithData:event.rrule];
    
    if (!self.attendees) {
        NSMutableSet *set = [NSMutableSet set];
        for (KGOEventAttendee *anAttendee in _kgoEvent.attendees) {
            [set addObject:[[[KGOAttendeeWrapper alloc] initWithKGOAttendee:anAttendee] autorelease]];
        }
        self.attendees = set;
    }
    
    if (!self.organizers) {
        NSMutableSet *set = [NSMutableSet set];
        for (KGOEventAttendee *anOrganizer in _kgoEvent.organizers) {
            [set addObject:[[[KGOAttendeeWrapper alloc] initWithKGOAttendee:anOrganizer] autorelease]];
        }
        self.attendees = set;
    }
    
    if (!self.userInfo) {
        self.userInfo = [NSKeyedUnarchiver unarchiveObjectWithData:_kgoEvent.userInfo];
    }
}

- (NSString *)placemarkID
{
    return nil;
}

@end
