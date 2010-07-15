#import "MKMapView+ArcGISAdditions.h"
#import "TileServerManager.h"
#import "MapTileOverlay.h"

@implementation MKMapView (ArcGISAdditions)

- (void)waitForTileServer {
    // use hard-coded initial locations
    self.region = MKCoordinateRegionMake(DEFAULT_MAP_CENTER, DEFAULT_MAP_SPAN);
}

- (void)tileServerDidSetup {
    CLLocationCoordinate2D initialLocation;
    CLLocationCoordinate2D nw = [TileServerManager northWestBoundary];
    CLLocationCoordinate2D se = [TileServerManager southEastBoundary];
    initialLocation.longitude = (nw.longitude + se.longitude) / 2;
    initialLocation.latitude = (nw.latitude + se.latitude) / 2;
    NSLog(@"initial location: %.3f %.3f", initialLocation.longitude, initialLocation.latitude);
    
    MKCoordinateSpan span = MKCoordinateSpanMake(initialLocation.longitude - nw.longitude, initialLocation.latitude - nw.latitude);
    MKCoordinateRegion region = MKCoordinateRegionMake(initialLocation, span);
    
    self.region = region;
    //[self overlayTiles];
}

- (void)overlayTiles {
    MapTileOverlay *overlay = [[MapTileOverlay alloc] init];
    [self addOverlay:overlay];
    [overlay release];
}

@end
