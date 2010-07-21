#import "MapTileOverlay.h"
#import "TileServerManager.h"

@implementation MapTileOverlay

- (id)init {
    if (self = [super init]) {
        CLLocationCoordinate2D nw = [TileServerManager northWestBoundary];
        CLLocationCoordinate2D se = [TileServerManager southEastBoundary];
        MKMapPoint mapNW = MKMapPointForCoordinate(nw);
        MKMapPoint mapSE = MKMapPointForCoordinate(se);
        boundingMapRect = MKMapRectMake(mapNW.x, mapSE.y, mapSE.x - mapNW.x, mapNW.y - mapSE.y);
        coordinate = CLLocationCoordinate2DMake((nw.latitude + se.latitude) / 2, (nw.longitude + se.longitude) / 2);
        NSLog(@"initialized MapTileOverlay with bounding rect: %.1f %.1f %.1f %.1f");
    }
    return self;
}


- (CLLocationCoordinate2D)coordinate {
    return coordinate;
}

- (MKMapRect)boundingMapRect {
    return boundingMapRect;
}

//- (BOOL)intersectsMapRect:(MKMapRect)mapRect

+ (NSString*)pathForTileAtLevel:(int)level row:(int)row col:(int)col {
	NSString* tileCachePath = [TileServerManager tileCachePath];
	return [tileCachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d/%d/%d", level, row, col]];
}

@end
