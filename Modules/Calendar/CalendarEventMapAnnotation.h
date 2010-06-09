#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@class MITCalendarEvent;

@interface CalendarEventMapAnnotation : NSObject <MKAnnotation> {
	
	MITCalendarEvent *event;

}

@property (nonatomic, retain) MITCalendarEvent *event;

- (NSInteger)eventID;
- (NSString *)subtitle;
- (NSString *)title;

@end
