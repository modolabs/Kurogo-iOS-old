#import <Foundation/Foundation.h>
#import "MITMobileWebAPI.h"
#import "MapZoomLevel.h"
#import "proj_api.h"

#define DEGREES_PER_RADIAN 180.0 / M_PI
#define RADIANS_PER_DEGREE M_PI / 180.0

@protocol TileServerDelegate

- (void)tileServerDidSetup;

@end

@class MapZoomLevel;

@interface TileServerManager : NSObject <JSONLoadedDelegate> {

    NSArray *_mapLevels;

    NSMutableDictionary *_serverInfo;
    MapZoomLevel *_baseMapLevel;
    
    projPJ *geo;
    projPJ *projection;

    NSMutableSet *_delegates;
    
    CGFloat _originX;
    CGFloat _originY;
    CGFloat _tileHeight;
    CGFloat _tileWidth;
    NSInteger _wkid;
    CGFloat _xMax;
    CGFloat _xMin;
    CGFloat _yMax;
    CGFloat _yMin;
    
    // earth measurements (for mercator projections)
    CGFloat _pixelsPerProjectedUnit;
    CGFloat _circumferenceInProjectedUnits;
    CGFloat _radiusInProjectedUnits;
    CGFloat _meridianLengthInProjectedUnits;
    BOOL _isWebMercator;
}

+ (BOOL)isInitialized;
+ (MapZoomLevel *)rootMapLevel;
+ (MapZoomLevel *)highestMapLevel;
+ (CGFloat)maximumZoomScale;

+ (NSArray *)mapLevels;
+ (CGFloat)tileWidth;
+ (CGFloat)tileHeight;

+ (CGFloat)originX;
+ (CGFloat)originY;

+ (CLLocationCoordinate2D)northWestBoundary;
+ (CLLocationCoordinate2D)southEastBoundary;

+ (CGFloat)circumferenceInProjectedUnits;
//+ (CGFloat)meridianLengthInProjectedUnits;

+ (CGPoint)projectedPointForMapPoint:(MKMapPoint)mapPoint;
+ (MKMapPoint)mapPointForProjectedPoint:(CGPoint)point;

+ (CGPoint)projectedPointForCoord:(CLLocationCoordinate2D)coord;
+ (CLLocationCoordinate2D)coordForProjectedPoint:(CGPoint)point;

+ (CGPoint)pixelPointForCoord:(CLLocationCoordinate2D)coord mapLevel:(MapZoomLevel *)mapLevel;
+ (CLLocationCoordinate2D)coordForPixelPoint:(CGPoint)pixel mapLevel:(MapZoomLevel *)mapLevel;

//+ (MapTile)mapLevel:(MapZoomLevel *)mapLevel tileForRowAtScreenPixel:(CGPoint)pixel;
//+ (CGSize)pixelSizeForMapLevel:(MapZoomLevel *)mapLevel;

+ (void)registerDelegate:(id<TileServerDelegate>)delegate;
+ (void)unregisterDelegate:(id<TileServerDelegate>)delegate;

@end
