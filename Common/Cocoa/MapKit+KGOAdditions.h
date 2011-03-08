#import <MapKit/MapKit.h>


@interface MKMapView (KGOAdditions)

- (void)centerAndZoomToDefaultRegion;
- (CGFloat)zoomLevel;
- (void)setZoomLevel:(CGFloat)zoomLevel;

+ (MKCoordinateSpan)coordinateSpanForZoomLevel:(CGFloat)zoomLevel;
+ (CGFloat)zoomLevelForCoordinateSpan:(MKCoordinateSpan)coordinateSpan;

@end
