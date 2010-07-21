#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface CalendarMapView : MKMapView {

	NSArray *_events;

}

@property (nonatomic, retain) NSArray *events;

@end
