#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "KGOSearchModel.h"

@class EKEvent, KGOEvent, KGOAttendeeWrapper, KGOCalendar;

@interface KGOEventWrapper : NSObject <KGOSearchResult, MKAnnotation> {
    
    EKEvent *_ekEvent;
    KGOEvent *_kgoEvent;
    
    // same type in eventkit and core data
    
    NSString * _identifier;
    NSDate *_endDate;
    NSDate *_startDate;
    NSDate *_lastUpdate; // lastModifiedDate in EKEvent
    BOOL _allDay;
    NSString *_location;
    NSString *_title;
    NSString *_summary; // notes in EKEvent
    
    // different type in eventkit and core data
    
    NSDictionary *_rrule; // recurrenceRule in EKEvent
    NSSet *_attendees;
    NSSet *_organizers; // KGOEventAttendee, EKParticipant
    
    // core data only -- no eventkit counterpart
    
    CLLocationCoordinate2D _coordinate;
    NSMutableSet *_calendars;
    BOOL _bookmarked;
    NSString *_briefLocation;
    NSDictionary *_userInfo;
    
    // not yet supported EKEvent properties: alarms, availability, isDetached,
    // status, calendar (this will be always set to local) 
}

@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSDate *startDate;
@property (nonatomic, retain) NSDate *endDate;
@property (nonatomic, retain) NSDate *lastUpdate;
@property (nonatomic, retain) NSString *location;
@property (nonatomic, retain) NSString *summary;
@property (nonatomic, retain) NSDictionary *rrule;
@property (nonatomic, retain) NSSet *organizers;
@property (nonatomic, retain) NSSet *attendees;
@property (nonatomic, retain) NSDictionary *userInfo;
@property (nonatomic) BOOL allDay;

// non-eventkit properties
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, retain) NSSet *calendars;
@property (nonatomic) BOOL bookmarked;
@property (nonatomic, retain) NSString *briefLocation;

// server api

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (void)updateWithDictionary:(NSDictionary *)dictionary;

// eventkit

- (id)initWithEKEvent:(EKEvent *)event;
- (EKEvent *)convertToEKEvent;
- (BOOL)saveToEventStore;

@property (nonatomic, retain) EKEvent *EKEvent; // setting this will override core data if saved

// core data

- (id)initWithKGOEvent:(KGOEvent *)event;
- (KGOEvent *)convertToKGOEvent;
- (void)saveToCoreData;
- (void)addCalendar:(KGOCalendar *)aCalendar;
- (NSSet *)unwrappedOrganizers;
- (NSSet *)unwrappedAttendees;

@property (nonatomic, retain) KGOEvent *KGOEvent; // setting this will override eventkit if saved

// subclass properties

- (NSString *)placemarkID;

@end
