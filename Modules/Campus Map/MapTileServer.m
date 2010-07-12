#import "MapTileServer.h"
#import "MapZoomLevel.h"
#import "proj_api.h"

#define DEGREES_PER_RADIAN 180.0 / M_PI
#define RADIANS_PER_DEGREE M_PI / 180.0

@implementation MapTileServer 

@dynamic name;
@dynamic originX; // false easting in mercator projections
@dynamic originY; // false northing in mercator projections
@dynamic projectionArgs;
@dynamic tileHeight;
@dynamic tileWidth;
@dynamic url;
@dynamic wkid; // Well Known ID for spatial reference.  102100 and 102113 are web mercator.
@dynamic xMax;
@dynamic xMin;
@dynamic yMax;
@dynamic yMin;
@dynamic zoomLevels;

- (NSArray *)sortedZoomLevels {
    NSSet *zoomLevelSet = self.zoomLevels;
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"level" ascending:YES];
    NSArray *sortedZoomLevels = [[zoomLevelSet allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
    [sort release];
    return sortedZoomLevels;
}

- (CGFloat)maximumZoomScale {
    //NSLog(@"%@", [self.zoomLevels description]);
    NSArray *sortedZoomLevels = [self sortedZoomLevels];
    //MapZoomLevel *rootZoomLevel = (MapZoomLevel *)[sortedZoomLevels objectAtIndex:0];
    MapZoomLevel *highestZoomLevel = (MapZoomLevel *)[sortedZoomLevels lastObject];
    return highestZoomLevel.zoomScale;
}

- (CGPoint)topLeftProjectedPoint {
    CGFloat x = [self.xMin doubleValue];
    CGFloat y = [self.yMax doubleValue];
    return CGPointMake(x, y);
}

- (CGPoint)bottomRightProjectedPoint {
    CGFloat x = [self.xMax doubleValue];
    CGFloat y = [self.yMin doubleValue];
    return CGPointMake(x, y);
}

#pragma mark calculations for mercator (google maps style) projections

- (CGFloat)circumferenceInProjectedUnits {
    return -2.0 * [self.originX doubleValue];
}

- (CGFloat)meridianLengthInProjectedUnits {
    return 2.0 * [self.originY doubleValue];
}

- (CGFloat)radiusInProjectedUnits {
    return [self circumferenceInProjectedUnits] / (2 * M_PI);
}

#pragma mark Conversions between lon/lat and projected units

- (CLLocationCoordinate2D)coordForProjectedPoint:(CGPoint)proj {
    CLLocationCoordinate2D coord;
    CGFloat c = [self circumferenceInProjectedUnits];
    CGFloat r = c / (2 * M_PI);
    coord.longitude = proj.x / c * 360.0;
    coord.latitude = 2 * (atan(exp(proj.y / r)) - M_PI / 4) * DEGREES_PER_RADIAN;
    return coord;
}

- (CGPoint)projectedPointForCoord:(CLLocationCoordinate2D)coord {
    CGFloat c = [self circumferenceInProjectedUnits];
    CGFloat r = c / (2 * M_PI);
    CGFloat x = coord.longitude / 360.0 * c;
    CGFloat y = r * log(tan(M_PI / 4 + coord.latitude / 2)) * RADIANS_PER_DEGREE;
    return CGPointMake(x, y);
}

@end
