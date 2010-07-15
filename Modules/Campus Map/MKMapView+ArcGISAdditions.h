#import <MapKit/MapKit.h>

#define DEFAULT_MAP_CENTER CLLocationCoordinate2DMake(42.374475, -71.117206)
#define DEFAULT_MAP_SPAN MKCoordinateSpanMake(2.0, 2.0)

@interface MKMapView (ArcGISAdditions)

- (void)waitForTileServer;
- (void)tileServerDidSetup;
- (void)overlayTiles;

@end
