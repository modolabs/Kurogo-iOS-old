/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import <Foundation/Foundation.h>
#import "JSONAPIRequest.h"
#import "MapZoomLevel.h"
#import "proj_api.h"

#define DEGREES_PER_RADIAN 180.0 / M_PI
#define RADIANS_PER_DEGREE M_PI / 180.0

#define DEFAULT_MAP_CENTER CLLocationCoordinate2DMake(42.374475, -71.117206)
#define DEFAULT_MAP_SPAN MKCoordinateSpanMake(2.0, 2.0)

@class MapZoomLevel;

@interface TileServerManager : NSObject <JSONAPIDelegate> {

    NSArray *_mapLevels;

    NSMutableDictionary *_serverInfo;
    MapZoomLevel *_baseMapLevel;
    
    projPJ *geo;
    projPJ *projection;

    //NSMutableSet *_delegates;
    NSMutableSet *_mapViews;
    
    CGFloat _originX;
    CGFloat _originY;
    CGFloat _tileHeight;
    CGFloat _tileWidth;
    NSInteger _wkid;
    CGFloat _xMax;
    CGFloat _xMin;
    CGFloat _yMax;
    CGFloat _yMin;
    
    MKCoordinateRegion _defaultRegion;
    CGFloat _defaultXMin;
    CGFloat _defaultXMax;
    CGFloat _defaultYMin;
    CGFloat _defaultYMax;
    
    // earth measurements (for mercator projections)
    CGFloat _pixelsPerProjectedUnit;
    CGFloat _circumferenceInProjectedUnits;
    CGFloat _radiusInProjectedUnits;
    CGFloat _meridianLengthInProjectedUnits;
    BOOL _isWebMercator;
    
    long long _mapTimestamp;
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
+ (MKCoordinateRegion)defaultRegion;

+ (CGFloat)circumferenceInProjectedUnits;

+ (CGPoint)projectedPointForMapPoint:(MKMapPoint)mapPoint;
+ (MKMapPoint)mapPointForProjectedPoint:(CGPoint)point;

+ (CGPoint)projectedPointForCoord:(CLLocationCoordinate2D)coord;
+ (CLLocationCoordinate2D)coordForProjectedPoint:(CGPoint)point;

//+ (void)registerMapView:(MKMapView *)mapView;
//+ (void)unregisterMapView:(MKMapView *)mapView;

+ (NSString *)tileCachePath;

@end
