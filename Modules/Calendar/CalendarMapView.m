#import "CalendarMapView.h"
#import "MITCalendarEvent.h"
#import "CalendarEventMapAnnotation.h"

@implementation CalendarMapView

@dynamic events;

- (NSArray *)events
{
	return _events;
}

/*
 * while setting events
 * create map annotations for all events that we can map
 * and get min/max lat/lon for map region
 */
- (void)setEvents:(NSArray *)events
{
	// make sure these events always belong to the controller that owns us
	_events = events;
	
	if (![[self selectedAnnotations] count]) {
		[self removeAnnotations:[self annotations]];
	} else {
		for (CalendarEventMapAnnotation *annotation in self.annotations) {
			if (annotation != [[self selectedAnnotations] lastObject]) {
				[self removeAnnotation:annotation];
			}
		}
	}
	
	double minLat = 90;
	double maxLat = -90;
	double minLon = 180;
	double maxLon = -180;
    
	for (MITCalendarEvent *event in [events reverseObjectEnumerator]) {
		if ([event hasCoords]) {
			CalendarEventMapAnnotation *annotation = [[[CalendarEventMapAnnotation alloc] init] autorelease];
			annotation.event = event;
			[self addAnnotation:annotation];
            
            double eventLat = [event.latitude doubleValue];
            double eventLon = [event.longitude doubleValue];
            if (eventLat < minLat) {
                minLat = eventLat;
            }
            if (eventLat > maxLat) {
                maxLat = eventLat;
            }
            if(eventLon < minLon) {
                minLon = eventLon;
            }
            if (eventLon > maxLon) {
                maxLon = eventLon;
            }
		}
	}
	
    if (minLat != 90) {
        CLLocationCoordinate2D center;
        center.latitude = minLat + (maxLat - minLat) / 2;
        center.longitude = minLon + (maxLon - minLon) / 2;
        
        double latDelta = maxLat - minLat;
        double lonDelta = maxLon - minLon; 
        
        MKCoordinateSpan span = MKCoordinateSpanMake(latDelta + latDelta / 4, lonDelta + lonDelta / 4);
        
        [self setRegion:MKCoordinateRegionMake(center, span)];
    }
}


@end
