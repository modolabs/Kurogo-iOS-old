#import "KGOEventWrapper.h"
#import <EventKit/EventKit.h>
#import "CalendarModel.h"
#import "Foundation+KGOAdditions.h"
#import "UIKit+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"

@implementation KGOEventWrapper

@synthesize identifier = _identifier,
startDate = _startDate,
endDate = _endDate,
lastUpdate = _lastUpdate,
allDay = _allDay,
fields = _fields,
location = _location,
briefLocation = _briefLocation,
title = _title,
summary = _summary,
rrule = _rrule,
coordinate = _coordinate,
calendars = _calendars,
bookmarked = _bookmarked, 
userInfo = _userInfo,
moduleTag;

#pragma mark KGOSearchResult

- (UIImage *)annotationImage
{
    return [UIImage imageWithPathName:@"modules/calendar/event_map_pin"];
}

- (NSString *)subtitle
{
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    return [dateFormatter stringFromDate:self.startDate]; 
}

- (BOOL)didGetSelected:(id)selector
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:self, @"searchResult",nil];
    return [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail forModuleTag:self.moduleTag params:params];
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
    NSString *identifier = [dictionary nonemptyStringForKey:@"id"];
    if (!identifier) {
        [self release];
        return nil;
    }
    
    self = [super init];
    if (self) {
        self.identifier = identifier;
        
        KGOEvent *storedEvent = [KGOEvent findEventWithID:self.identifier];
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
    self.title = [dictionary nonemptyStringForKey:@"title"];

    // Check for v1 field
    self.summary = [dictionary nonemptyStringForKey:@"description"];
    
    // time
    NSTimeInterval startTimestamp = [dictionary floatForKey:@"start"];
    self.startDate = [NSDate dateWithTimeIntervalSince1970:startTimestamp];

    NSTimeInterval endTimestamp = [dictionary floatForKey:@"end"];
    if (endTimestamp > startTimestamp) {
        self.endDate = [NSDate dateWithTimeIntervalSince1970:endTimestamp];
    }
    NSNumber *allDay = [dictionary objectForKey:@"allday"];
    if (allDay && [allDay isKindOfClass:[NSNumber class]]) {
        self.allDay = [allDay boolValue];
    } else {
        self.allDay = (endTimestamp - startTimestamp) + 1 >= 24 * 60 * 60;
    }
    
    // Check for v1 field
    self.location = [dictionary nonemptyStringForKey:@"location"];
    
    // Generic fields
    self.fields = [dictionary objectForKey:@"fields"];
    
    // Pull out specific v2 common fields (will overwrite any v1 fields if present)
    for (NSDictionary *field in self.fields) {
        NSString *key = [field nonemptyStringForKey:@"id"];
        
        // summary
        if ([key isEqualToString:@"description"]) {
            self.summary = [field nonemptyStringForKey:@"value"];
        }
        
        // location
        if ([key isEqualToString:@"location"]) {
            self.location = [field nonemptyStringForKey:@"value"];
        }
    }
    
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
    // TODO: read recurrenceRule, attendees, and organizer
    
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

    // TODO: write recurrenceRule.  attendees and organizer are
    // not writeable as of the latest SDK.
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
    
    NSSet *unwrappedOrganizers = [self unwrappedOrganizers];
    if (unwrappedOrganizers.count) {
        if (!_kgoEvent) {
            [self convertToKGOEvent];
        }

        for (KGOEventParticipant *anOrganizer in unwrappedOrganizers) {
            KGOEventParticipantRelation *relation = [KGOEventParticipantRelation relationWithEvent:_kgoEvent participant:anOrganizer];
            relation.isOrganizer = [NSNumber numberWithBool:YES];
        }
        
    } else if (_kgoEvent) {
        for (KGOAttendeeWrapper *wrapper in _organizers) {
            [wrapper convertToKGOAttendee];
            KGOEventParticipant *anOrganizer = [wrapper KGOAttendee];
            KGOEventParticipantRelation *relation = [KGOEventParticipantRelation relationWithEvent:_kgoEvent participant:anOrganizer];
            relation.isOrganizer = [NSNumber numberWithBool:YES];
        }
    }
}

- (NSSet *)unwrappedOrganizers
{
    if (!self.organizers.count)
        return nil;
    
    NSMutableSet *set = [NSMutableSet set];
    for (KGOAttendeeWrapper *wrapper in self.organizers) {
        KGOEventParticipant *attendee = [wrapper KGOAttendee];
        if (attendee) {
            [set addObject:attendee];
        }
    }
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
        }
        
        for (KGOEventParticipant *anAttendee in unwrappedAttendees) {
            KGOEventParticipantRelation *relation = [KGOEventParticipantRelation relationWithEvent:_kgoEvent participant:anAttendee];
            relation.isAttendee = [NSNumber numberWithBool:YES];
        }
        
    } else if (_kgoEvent) {
        for (KGOAttendeeWrapper *wrapper in _attendees) {
            [wrapper convertToKGOAttendee];
            KGOEventParticipant *anAttendee = [wrapper KGOAttendee];
            KGOEventParticipantRelation *relation = [KGOEventParticipantRelation relationWithEvent:_kgoEvent participant:anAttendee];
            relation.isAttendee = [NSNumber numberWithBool:YES];
        }
    }
}

- (NSSet *)unwrappedAttendees
{
    if (!self.attendees.count)
        return nil;
    
    NSMutableSet *set = [NSMutableSet set];
    for (KGOAttendeeWrapper *wrapper in self.attendees) {
        KGOEventParticipant *attendee = [wrapper KGOAttendee];
        if (attendee) {
            [set addObject:attendee];
        }
    }
    return set;
}

- (KGOEvent *)convertToKGOEvent
{
    if (!_kgoEvent) {
        _kgoEvent = [[KGOEvent eventWithID:self.identifier] retain];
    }

    _kgoEvent.title = self.title;
    _kgoEvent.location = self.location;
    _kgoEvent.briefLocation = self.briefLocation;
    _kgoEvent.start = self.startDate;
    _kgoEvent.end = self.endDate;
    _kgoEvent.latitude = [NSNumber numberWithFloat:self.coordinate.latitude];
    _kgoEvent.longitude = [NSNumber numberWithFloat:self.coordinate.longitude];
    _kgoEvent.summary = self.summary;
    _kgoEvent.calendars = _calendars;

    for (KGOEventParticipantRelation *aRelation in _kgoEvent.particpants) {
        [[CoreDataManager sharedManager] deleteObject:aRelation];
    }
    _kgoEvent.particpants = nil;
    
    [[self unwrappedOrganizers] enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        KGOEventParticipantRelation *relation = [KGOEventParticipantRelation relationWithEvent:_kgoEvent participant:obj];
        relation.isOrganizer = [NSNumber numberWithBool:YES];
    }];
    [[self unwrappedAttendees] enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        KGOEventParticipantRelation *relation = [KGOEventParticipantRelation relationWithEvent:_kgoEvent participant:obj];
        relation.isAttendee = [NSNumber numberWithBool:YES];
    }];
    
    if (_userInfo) {
        _kgoEvent.userInfo = [NSKeyedArchiver archivedDataWithRootObject:_userInfo];
    }
    
    _kgoEvent.lastUpdate = [NSDate date];
    
    // new in v2:
    _kgoEvent.allDay = [NSNumber numberWithBool:self.allDay];
    
    if (_fields) {
        _kgoEvent.fields = [NSKeyedArchiver archivedDataWithRootObject:_fields];
    }
    
    return _kgoEvent;
}

- (void)addCalendar:(KGOCalendar *)aCalendar
{
    if (!self.calendars) {
        self.calendars = [NSMutableSet set];
    }
    [self.calendars addObject:aCalendar];

    if (_kgoEvent) {
        [aCalendar addEventsObject:_kgoEvent];
    }
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
    [[CoreDataManager sharedManager] saveData];
}

- (void)removeBookmark
{
    if (self.KGOEvent) {
        self.KGOEvent.bookmarked = [NSNumber numberWithBool:NO];
        [[CoreDataManager sharedManager] saveData];
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
    if (!self.calendars)     self.calendars     = [[_kgoEvent.calendars mutableCopy] autorelease];
    
    self.coordinate = CLLocationCoordinate2DMake([_kgoEvent.latitude floatValue], [_kgoEvent.longitude floatValue]);

    if (!self.rrule && _kgoEvent.rrule) {
        self.rrule = [NSKeyedUnarchiver unarchiveObjectWithData:event.rrule];
    }
    
    NSMutableSet *attendees = [NSMutableSet set];
    NSMutableSet *organizers = [NSMutableSet set];
    DLog(@"%d participants", _kgoEvent.particpants.count);
    [_kgoEvent.particpants enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        KGOEventParticipantRelation *relation = (KGOEventParticipantRelation *)obj;
        KGOEventParticipant *participant = relation.participant;
        KGOAttendeeWrapper *wrapper = [[[KGOAttendeeWrapper alloc] initWithKGOAttendee:participant] autorelease];
        if ([relation.isAttendee boolValue]) {
            [attendees addObject:wrapper];
        } else if ([relation.isOrganizer boolValue]) {
            [organizers addObject:wrapper];
        }
    }];

    if (!self.attendees) {
        self.attendees = attendees;
    }
    
    if (!self.organizers) {
        self.organizers = organizers;
    }
    
    if (!self.userInfo && _kgoEvent.userInfo) {
        self.userInfo = [NSKeyedUnarchiver unarchiveObjectWithData:_kgoEvent.userInfo];
    }

    // new in v2:
    if (_kgoEvent.allDay) {
        self.allDay = [_kgoEvent.allDay boolValue];
    }
    
    if (!self.fields && _kgoEvent.fields) {
        self.fields = [NSKeyedUnarchiver unarchiveObjectWithData:_kgoEvent.fields];
    }
}

- (NSString *)placemarkID
{
    return nil;
}

@end
