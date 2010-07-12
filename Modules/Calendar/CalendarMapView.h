#import <Foundation/Foundation.h>
#import "MITMapView.h"

@interface CalendarMapView : MKMapView {

	NSArray *_events;

}

@property (nonatomic, retain) NSArray *events;

@end
