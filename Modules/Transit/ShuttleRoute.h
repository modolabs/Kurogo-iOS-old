#import <Foundation/Foundation.h>
#import "MITMapRoute.h"
#import "ShuttleRouteCache.h"

@interface ShuttleRoute : NSObject <MITMapRoute> {
    NSString *_tag;
    BOOL _gpsActive;
    BOOL _isRunning;
	BOOL _liveStatusFailed;
	ShuttleRouteCache *_cache;
	NSString * agency;
	NSString *genericUrlForMarker;
	NSString *nextStopId;
	NSString *urlForStopMarker;
	
	
    NSMutableArray *_stops;
	
	// parsed path locations for the entire route. 
	NSMutableArray* _pathLocations;
	
	// annotaions for each shuttle stop 
	NSMutableArray* _stopAnnotations;
	
	// locations, if available of any vehicles on the route. 
	NSArray* _vehicleLocations;
	
	UIImage *genericShuttleMarker;
}

- (id)initWithCache:(ShuttleRouteCache *)cachedRoute;
- (void)updateInfo:(NSDictionary *)routeInfo;
- (NSString *)trackingStatus;
- (void)getStopsFromCache;
- (void)updatePath;

@property (readwrite, retain) NSString *tag;
@property (readwrite, retain) NSArray* vehicleLocations;

@property (readonly) NSString *fullSummary;
@property (assign) BOOL gpsActive;
@property (assign) BOOL isRunning;
@property (assign) BOOL liveStatusFailed;
@property (readwrite, retain) ShuttleRouteCache *cache;
@property (readwrite, retain) NSString * agency;
@property (readwrite, retain) NSString * color;
@property (readwrite, retain) NSString *genericUrlForMarker;
@property (readwrite, retain) NSString *nextStopId;
@property (readwrite, retain) NSString *urlForStopMarker;
@property (nonatomic, retain) UIImage *genericShuttleMarker;

@property (readwrite, retain) NSString *routeDescription;
@property (readwrite, retain) NSString *title;
@property (readwrite, retain) NSString *summary;
@property (nonatomic, retain) NSString *routeID;
@property (assign) NSInteger interval;
@property (readwrite, retain) NSMutableArray *stops;
@property (assign) NSInteger sortOrder;
@property (readwrite, retain) NSArray *path;

@end
