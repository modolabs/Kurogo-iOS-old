#import "TileServerManager.h"
#import "CoreDataManager.h"
#import <MapKit/MapKit.h>

@interface TileServerManager (Private)

+ (TileServerManager *)manager;

- (NSString *)serverFilename;
- (void)saveData;
- (void)setupServerInfo:(NSDictionary *)serverInfo;

- (NSArray *)mapLevels;
- (CGFloat)tileWidth;
- (CGFloat)tileHeight;

- (CGFloat)originX;
- (CGFloat)originY;

- (CLLocationCoordinate2D)northWestBoundary;
- (CLLocationCoordinate2D)southEastBoundary;

- (CGFloat)circumferenceInProjectedUnits;
- (CGFloat)meridianLengthInProjectedUnits;

- (MKCoordinateRegion)defaultRegion;

- (BOOL)isInitialized;
- (MapZoomLevel *)rootMapLevel;
- (MapZoomLevel *)highestMapLevel;
- (void)getProjectionArgs;

- (CGPoint)projectedPointForMapPoint:(MKMapPoint)mapPoint;
- (MKMapPoint)mapPointForProjectedPoint:(CGPoint)point;

- (CGPoint)projectedPointForCoord:(CLLocationCoordinate2D)coord error:(NSError **)error;
- (CLLocationCoordinate2D)coordForProjectedPoint:(CGPoint)point error:(NSError **)error;

- (void)setupProjection:(const char *)projString;

//- (void)registerMapView:(MKMapView *)mapView;
//- (void)unregisterMapView:(MKMapView *)mapView;

+ (NSString*)mapTimestampFilename;

@end

static TileServerManager *s_manager = nil;
static NSString * s_tileServerFilename = @"tileServer.plist";

@implementation TileServerManager

#pragma mark Public methods

+ (NSArray *)mapLevels {
    return [[TileServerManager manager] mapLevels];
}

+ (CGFloat)tileWidth {
    return [[TileServerManager manager] tileWidth];
}

+ (CGFloat)tileHeight {
    return [[TileServerManager manager] tileHeight];
}

+ (BOOL)isInitialized {
    return [[TileServerManager manager] isInitialized];
}

+ (MapZoomLevel *)rootMapLevel {
    return [[TileServerManager manager] rootMapLevel];
}

+ (MapZoomLevel *)highestMapLevel {
    return [[TileServerManager manager] highestMapLevel];
}

+ (CGFloat)maximumZoomScale {
    return [[TileServerManager manager] highestMapLevel].zoomScale;
}

+ (CLLocationCoordinate2D)northWestBoundary {
    return [[TileServerManager manager] northWestBoundary];
}

+ (CLLocationCoordinate2D)southEastBoundary {
    return [[TileServerManager manager] southEastBoundary];
}

+ (CGFloat)originX {
    return [[TileServerManager manager] originX];
}

+ (CGFloat)originY {
    return [[TileServerManager manager] originY];
}

+ (CGFloat)circumferenceInProjectedUnits {
    return [[TileServerManager manager] circumferenceInProjectedUnits];
}

+ (CGPoint)projectedPointForMapPoint:(MKMapPoint)mapPoint {
    return [[TileServerManager manager] projectedPointForMapPoint:mapPoint];
}

+ (MKMapPoint)mapPointForProjectedPoint:(CGPoint)point {
    return [[TileServerManager manager] mapPointForProjectedPoint:point];
}

+ (CGPoint)projectedPointForCoord:(CLLocationCoordinate2D)coord {
    NSError *error = nil;
    CGPoint result = [[TileServerManager manager] projectedPointForCoord:coord error:&error];
    if (error != nil) {
        NSLog(@"%@ error %d: %@", error.domain, error.code, error.userInfo);
    }
    return result;
}

+ (CLLocationCoordinate2D)coordForProjectedPoint:(CGPoint)point {
    NSError *error = nil;
    CLLocationCoordinate2D result = [[TileServerManager manager] coordForProjectedPoint:point error:&error];
    if (error != nil) {
        NSLog(@"%@ error %d: %@", error.domain, error.code, error.userInfo);
    }
    return result;
}

+ (MKCoordinateRegion)defaultRegion {
    return [[TileServerManager manager] defaultRegion];
}
/*
+ (void)registerMapView:(MKMapView *)mapView {
    [[TileServerManager manager] registerMapView:mapView];
}

+ (void)unregisterMapView:(MKMapView *)mapView {
    [[TileServerManager manager] unregisterMapView:mapView];
}
*/
#pragma mark -
#pragma mark Private methods

+ (TileServerManager *)manager {
    if (s_manager == nil) {
        s_manager = [[TileServerManager alloc] init];
    }
    return s_manager;
}

#define kLastUpdatedKey @"last_updated"

- (id)init {
    if (self = [super init]) {
        BOOL didSetup = NO;
        
        NSString *filename = [self serverFilename];
        _serverInfo = [[NSMutableDictionary dictionaryWithContentsOfFile:filename] retain];
        
        if (_serverInfo != nil) {
            NSDate *date = [_serverInfo objectForKey:@"lastupdated"];
            //NSLog(@"%@", _serverInfo);
            if ([[NSDate date] timeIntervalSinceDate:date] <= 86400) {
                [self setupServerInfo:_serverInfo];
                didSetup = YES;
            }
        }
        
        if (!didSetup) {
            JSONAPIRequest *request = [JSONAPIRequest requestWithJSONAPIDelegate:self];
            request.userData = [NSString stringWithString:@"capabilities"];
            [request requestObjectFromModule:@"map" command:@"capabilities" parameters:nil];
        }
        
        // handle last update
        
		NSDictionary* dictionary = [NSDictionary dictionaryWithContentsOfFile:[TileServerManager mapTimestampFilename]];
		_mapTimestamp = [[dictionary objectForKey:kLastUpdatedKey] longLongValue];
        
        JSONAPIRequest *updateRequest = [JSONAPIRequest requestWithJSONAPIDelegate:self];
        updateRequest.userData = [NSString stringWithString:@"updated"];
        [updateRequest requestObjectFromModule:@"map" command:@"tilesupdated" parameters:nil];
    }
    return self;
}

- (NSArray *)mapLevels {
    return _mapLevels;
}

- (CGFloat)tileWidth {
    return _tileWidth;
}

- (CGFloat)tileHeight {
    return _tileHeight;
}

- (BOOL)isInitialized {
    if (geo && projection) {
        return YES;
    }
    return NO;
}

- (NSString *)serverFilename {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* documentPath = [paths objectAtIndex:0];
	return [documentPath stringByAppendingPathComponent:s_tileServerFilename];
}

+ (NSString*)mapTimestampFilename
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* documentPath = [paths objectAtIndex:0];
	return [documentPath stringByAppendingPathComponent:@"mapTimestamp.plist"];	
}

+ (NSString *)tileCachePath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString* cachePath = [paths objectAtIndex:0];
	return [cachePath stringByAppendingPathComponent:@"tile"];
}

- (void)saveData {
	NSString *filename = [self serverFilename];
	BOOL saved = [_serverInfo writeToFile:filename atomically:YES];
	NSLog(@"Saved file: %@ %@", filename, saved ? @"SUCCESS" : @"FAIL");
    if (!saved) {
        NSLog(@"could not save file with contents %@", [_serverInfo description]);
    }
}

- (MapZoomLevel *)rootMapLevel {
    return _baseMapLevel;
}

- (MapZoomLevel *)highestMapLevel {
    return (MapZoomLevel *)[_mapLevels lastObject];
}

// TODO: figure out if i have the y coordinates backwards
// i.e. increasing downwards when it should be upwards
// (currently no class seems to be using these as direction
// indicators so we haven't seen problems yet)

- (CLLocationCoordinate2D)southEastBoundary {
    CGPoint topLeftProjectedPoint = CGPointMake(_xMax, _yMax);
    NSError *error = nil;
    CLLocationCoordinate2D se = [self coordForProjectedPoint:topLeftProjectedPoint error:&error];
    return se;
}

- (CLLocationCoordinate2D)northWestBoundary {
    CGPoint topLeftProjectedPoint = CGPointMake(_xMin, _yMin);
    NSError *error = nil;
    CLLocationCoordinate2D nw = [self coordForProjectedPoint:topLeftProjectedPoint error:&error];
    return nw;
}

- (MKCoordinateRegion)defaultRegion {
    if ([self isInitialized]) {
        if (_defaultRegion.span.latitudeDelta == 0) {
            NSError *error = nil;
            CGPoint point = CGPointMake((_defaultXMin + _defaultXMax) / 2,
                                        (_defaultYMin + _defaultYMax) / 2);
            CLLocationCoordinate2D centerCoord = [self coordForProjectedPoint:point error:&error];

            point = CGPointMake(_defaultXMax, _defaultYMax);
            CLLocationCoordinate2D cornerCoord = [self coordForProjectedPoint:point error:&error];
            
            // the initialExtent returned by the harvard server is really zoomed in
            // so we increase the span a little
            MKCoordinateSpan span = MKCoordinateSpanMake((cornerCoord.latitude - centerCoord.latitude) * 4,
                                                         (cornerCoord.longitude - centerCoord.longitude) * 4);
            
            _defaultRegion = MKCoordinateRegionMake(centerCoord, span);
        }
        return _defaultRegion;
    } else {
        return MKCoordinateRegionMake(DEFAULT_MAP_CENTER, DEFAULT_MAP_SPAN);
    }
}

- (CGFloat)originX {
    return _originX;
}

- (CGFloat)originY {
    return _originY;
}

- (CGFloat)circumferenceInProjectedUnits {
    return _circumferenceInProjectedUnits;
}

- (CGFloat)meridianLengthInProjectedUnits {
    return _meridianLengthInProjectedUnits;
}

// TODO: add NSError argument if conversion fails
- (CGPoint)projectedPointForCoord:(CLLocationCoordinate2D)coord error:(NSError **)error {
    //NSLog(@"converting from coord: %.4f, %.4f", coord.longitude, coord.latitude);
    if (_isWebMercator) {
        CGFloat x = coord.longitude / 360.0 * _circumferenceInProjectedUnits;
        CGFloat y = _radiusInProjectedUnits * log(tan(M_PI / 4 + coord.latitude / 2)) * RADIANS_PER_DEGREE;
        //NSLog(@"converted to point: %.1f, %.1f", x, y);
        return CGPointMake(x, y);
    } else {
        double x = coord.longitude * RADIANS_PER_DEGREE;
        double y = coord.latitude * RADIANS_PER_DEGREE;
        int status = pj_transform(geo, projection, 1, 1, &x, &y, NULL);
        if (status != 0) {
            if (error != NULL) {
                NSString *message = [NSString stringWithFormat:@"failed to convert lat/lon to projected point: pj_transform error %d", status];
                *error = [NSError errorWithDomain:MapsErrorDomain
                                             code:errMapProjection
                                         userInfo:[NSDictionary dictionaryWithObjectsAndKeys:message, @"message", nil]];
            }
        }
        //NSLog(@"converted to point: %.1f, %.1f", x, y);
        return CGPointMake(x, y);
    }
}

- (CLLocationCoordinate2D)coordForProjectedPoint:(CGPoint)point error:(NSError **)error {
    //NSLog(@"converting from point: %.1f, %.1f", point.x, point.y);
    if (_isWebMercator) {
        CLLocationCoordinate2D coord;
        coord.longitude = point.x / _circumferenceInProjectedUnits * 360.0;
        coord.latitude = 2 * (atan(exp(point.y / _radiusInProjectedUnits)) - M_PI / 4) * DEGREES_PER_RADIAN;
        //NSLog(@"converted to coord: %.3f, %.3f", coord.longitude, coord.latitude);
        return coord;
    } else {
        double x = point.x;
        double y = point.y;
        int status = pj_transform(projection, geo, 1, 1, &x, &y, NULL);
        if (status != 0) {
            if (error != NULL) {
                NSString *message = [NSString stringWithFormat:@"failed to convert projected point to lat/lon: pj_transform error %d", status];
                *error = [NSError errorWithDomain:MapsErrorDomain
                                             code:errMapProjection
                                         userInfo:[NSDictionary dictionaryWithObjectsAndKeys:message, @"message", nil]];
            }
        }
        //NSLog(@"converted to coord: %.3f, %.3f", x * DEGREES_PER_RADIAN, y * DEGREES_PER_RADIAN);
        return CLLocationCoordinate2DMake(y * DEGREES_PER_RADIAN, x * DEGREES_PER_RADIAN);
    }
}

- (void)getProjectionArgs {
    NSString *wkid = [NSString stringWithFormat:@"%d", _wkid];
    JSONAPIRequest *request = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    request.userData = @"projection";
    [request requestObjectFromModule:@"map" command:@"proj4specs" parameters:[NSDictionary dictionaryWithObjectsAndKeys:wkid, @"wkid", nil]];
}
/*
- (void)registerMapView:(MKMapView *)mapView {
    if (!_mapViews) {
        _mapViews = [[NSMutableSet alloc] initWithCapacity:1];
    }
    [_mapViews addObject:mapView];
    
    if ([TileServerManager isInitialized]) {
        [mapView tileServerDidSetup];
    } else {
        [mapView waitForTileServer];
    }
}

- (void)unregisterMapView:(MKMapView *)mapView {
    if ([_mapViews containsObject:mapView]) {
        [_mapViews removeObject:mapView];
    }
}
*/
- (void)setupServerInfo:(NSMutableDictionary *)serverInfo {
    
    NSInteger rootLevel = 0;
    
    NSArray *layers = [serverInfo objectForKey:@"layers"];
    NSMutableArray *cleanedUpLayers = [NSMutableArray arrayWithCapacity:[layers count]];
    for (NSDictionary *layerInfo in layers) {
        NSMutableDictionary *cleanedUpLayerInfo = [NSMutableDictionary dictionaryWithDictionary:layerInfo];
        [cleanedUpLayerInfo removeObjectForKey:@"subLayerIds"];
        [cleanedUpLayers addObject:cleanedUpLayerInfo];
    }
    [serverInfo setObject:cleanedUpLayers forKey:@"layers"];
    
    NSDictionary *extent = [serverInfo objectForKey:@"fullExtent"];
    _xMax = [[extent objectForKey:@"xmax"] doubleValue];
    _xMin = [[extent objectForKey:@"xmin"] doubleValue];
    _yMax = [[extent objectForKey:@"ymax"] doubleValue];
    _yMin = [[extent objectForKey:@"ymin"] doubleValue];

    // one-time values for calculation of defaultRegion
    extent = [serverInfo objectForKey:@"initialExtent"];
    _defaultXMax = [[extent objectForKey:@"xmax"] doubleValue];
    _defaultXMin = [[extent objectForKey:@"xmin"] doubleValue];
    _defaultYMax = [[extent objectForKey:@"ymax"] doubleValue];
    _defaultYMin = [[extent objectForKey:@"ymin"] doubleValue];
        
    NSDictionary *tileInfo = [serverInfo objectForKey:@"tileInfo"];
    _tileHeight = [[tileInfo objectForKey:@"rows"] doubleValue];
    _tileWidth = [[tileInfo objectForKey:@"cols"] doubleValue];
    _wkid = [[[tileInfo objectForKey:@"spatialReference"] objectForKey:@"wkid"] intValue];
    
    NSDictionary *origin = [tileInfo objectForKey:@"origin"];
    _originX = [[origin objectForKey:@"x"] doubleValue];
    _originY = [[origin objectForKey:@"y"] doubleValue];
    
    // take care of map levels
    
    // tile (row|col) by pixels per projected unit
    CGFloat minRowInProjectedUnits = (_originY - _yMax) / _tileHeight;
    CGFloat minColInProjectedUnits = (_xMin - _originX) / _tileWidth;
    CGFloat maxRowInProjectedUnits = (_originY - _yMin) / _tileHeight;
    CGFloat maxColInProjectedUnits = (_xMax - _originX) / _tileWidth;
    
    NSArray *levelsOfDetail = [tileInfo objectForKey:@"lods"];
    NSMutableArray *zoomLevels = [NSMutableArray arrayWithCapacity:[levelsOfDetail count]];
                                  
    CGFloat baseResolution;
    
    for (NSDictionary *levelOfDetail in levelsOfDetail) {
        MapZoomLevel *zoomLevel = [[MapZoomLevel alloc] init];
        
        CGFloat resolution = [[levelOfDetail objectForKey:@"resolution"] doubleValue];
        zoomLevel.resolution = resolution;
        
        zoomLevel.minRow = round(minRowInProjectedUnits / resolution);
        zoomLevel.minCol = round(minColInProjectedUnits / resolution);
        zoomLevel.maxRow = round(maxRowInProjectedUnits / resolution);
        zoomLevel.maxCol = round(maxColInProjectedUnits / resolution);
        
        NSInteger level = [[levelOfDetail objectForKey:@"level"] intValue];
        zoomLevel.level = level;
        
        if (level == rootLevel) {
            baseResolution = resolution;
            _baseMapLevel = zoomLevel;
        }
        
        zoomLevel.scale = [[levelOfDetail objectForKey:@"scale"] floatValue];
        [zoomLevels addObject:zoomLevel];
    }
    
    _mapLevels = [[NSArray arrayWithArray:zoomLevels] retain];
    
    // take care of projection

    NSLog(@"wkid %d", _wkid);
    if (_wkid == 102100 || _wkid == 102113) {
        _isWebMercator = YES;

        _circumferenceInProjectedUnits = -2.0 * _originX;
        _pixelsPerProjectedUnit = MKMapSizeWorld.width / _circumferenceInProjectedUnits;
        _radiusInProjectedUnits = _circumferenceInProjectedUnits / (2 * M_PI);
        _meridianLengthInProjectedUnits = MKMapSizeWorld.height / _pixelsPerProjectedUnit;
    
    } else {
        geo = pj_init_plus("+proj=latlong +ellps=clrk66");
        
        NSString *projectionArgs = [serverInfo objectForKey:@"projectionArgs"];
        if (projectionArgs) {
            const char *projString = [projectionArgs cStringUsingEncoding:[NSString defaultCStringEncoding]];
            [self setupProjection:projString];
            //projection = pj_init_plus(projString);
        } else {
            [self getProjectionArgs];
            return;
        }
    }
    
    //for (MKMapView *aMapView in _mapViews) {
    //    [aMapView tileServerDidSetup];
    //}
}

- (void)setupProjection:(const char *)projString {
    projection = pj_init_plus(projString);
    
    CLLocationCoordinate2D west = CLLocationCoordinate2DMake(0.0, -180.0);
    CLLocationCoordinate2D east = CLLocationCoordinate2DMake(0.0, 180.0);

    _circumferenceInProjectedUnits = -2 * _originX;
    
    for (MapZoomLevel *zoomLevel in _mapLevels) {
        CGFloat numTilesAcrossEquator = _circumferenceInProjectedUnits / zoomLevel.resolution;
        //NSLog(@"level %d has %d tiles across equator", zoomLevel.level, (int)floor(numTilesAcrossEquator));
        //NSLog(@"and %d tiles per row", zoomLevel.maxCol - zoomLevel.minCol + 1);
        //NSLog(@"and %d tiles per column", zoomLevel.maxRow - zoomLevel.minRow + 1);
        
        zoomLevel.zoomScale = numTilesAcrossEquator / MKMapSizeWorld.width;
    }
	
	// This lets those that have been waiting for the TileServerManager know that it's ready to use. 
	// View controllers that want to react to this should register for this notification. 
	// The alternative is for the view controller to pass the view to registerMapView. In that case, TileServerManager 
	// will notify the view directly that it's ready via the tileServerDidSetup method, bypassing the view controller.
	[[NSNotificationCenter defaultCenter] postNotificationName:kTileServerManagerProjectionIsReady object:nil];	
}

- (CGPoint)projectedPointForMapPoint:(MKMapPoint)mapPoint {
    //NSLog(@"converting from point: %.4f %.4f", mapPoint.x, mapPoint.y);
    if (_isWebMercator) {
        CGPoint point;
        point.x = mapPoint.x / _pixelsPerProjectedUnit;
        point.y = mapPoint.y / _pixelsPerProjectedUnit;
        return point;
    } else {
        CLLocationCoordinate2D coord = MKCoordinateForMapPoint(mapPoint);
        NSError *error = nil;
        CGPoint point = [self projectedPointForCoord:coord error:&error];
        return point;
    }
}

- (MKMapPoint)mapPointForProjectedPoint:(CGPoint)point {
    //NSLog(@"converting from point: %.4f %.4f", point.x, point.y);
    if (_isWebMercator) {
        MKMapPoint mapPoint;
        mapPoint.x = point.x * _pixelsPerProjectedUnit;
        mapPoint.y = point.y * _pixelsPerProjectedUnit;
        return mapPoint;
    } else {
        NSError *error = nil;
        CLLocationCoordinate2D coord = [self coordForProjectedPoint:point error:&error];
        return MKMapPointForCoordinate(coord);
    }
}

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result {
    if ([request.userData isEqualToString:@"updated"]) {
        NSDictionary* dictionary = (NSDictionary *)result;
        long long newMapTimestamp = [[dictionary objectForKey:kLastUpdatedKey] longLongValue];
        
        if (newMapTimestamp > _mapTimestamp) {
            // store the new timestamp and wipe out the cache.
            NSLog(@"new map tiles found");
            [dictionary writeToFile:[TileServerManager mapTimestampFilename] atomically:YES];
            
            NSString* tileCachePath = [TileServerManager tileCachePath];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:tileCachePath]) {
                NSError* error = nil;
                if (![[NSFileManager defaultManager] removeItemAtPath:tileCachePath error:&error]) {
                    NSLog(@"Error wiping out map cache: %@", error);
                }
            }
        }
        
        return;
    }
    
    if (result && [result isKindOfClass:[NSDictionary class]]) {
        if ([request.userData isEqualToString:@"projection"]) {
            
            NSString *projectionArgs = [result objectForKey:@"properties"];
            [_serverInfo setObject:projectionArgs forKey:@"projectionArgs"];
            [self saveData];
            
            [self setupProjection:[projectionArgs cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            
            //for (MKMapView *aMapView in _mapViews) {
            //    [aMapView tileServerDidSetup];
            //}
            
        } else {
            _serverInfo = [[NSMutableDictionary alloc] initWithDictionary:result];
            [_serverInfo setObject:[NSDate date] forKey:@"lastupdated"];
            
            [self setupServerInfo:_serverInfo];
        }
    }
}

- (void)handleConnectionFailureForRequest:(JSONAPIRequest *)request {
	// TODO: handle connection failure
}

- (void)dealloc {
    pj_free(projection);
    pj_free(geo);
    
    [_mapLevels release];
    [_serverInfo release];
    [super dealloc];
}

@end
