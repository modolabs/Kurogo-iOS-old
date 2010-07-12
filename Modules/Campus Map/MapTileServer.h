/* MapTileServer.h
 *
 * Cached representation of an ESRI ArcGIS tile server.
 */
#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>

@interface MapTileServer :  NSManagedObject  
{
}

- (NSArray *)sortedZoomLevels;
- (CGFloat)maximumZoomScale;
- (CGFloat)circumferenceInProjectedUnits;
- (CGFloat)meridianLengthInProjectedUnits;
- (CGFloat)radiusInProjectedUnits;
- (CLLocationCoordinate2D)coordForProjectedPoint:(CGPoint)proj;
- (CGPoint)projectedPointForCoord:(CLLocationCoordinate2D)coord;
- (CGPoint)bottomRightProjectedPoint;
- (CGPoint)topLeftProjectedPoint;

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * originX;
@property (nonatomic, retain) NSNumber * originY;
@property (nonatomic, retain) NSString * projectionArgs;
@property (nonatomic, retain) NSNumber * tileHeight;
@property (nonatomic, retain) NSNumber * tileWidth;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * wkid;
@property (nonatomic, retain) NSNumber * xMax;
@property (nonatomic, retain) NSNumber * xMin;
@property (nonatomic, retain) NSNumber * yMax;
@property (nonatomic, retain) NSNumber * yMin;
@property (nonatomic, retain) NSSet* zoomLevels;

@end


@interface MapTileServer (CoreDataGeneratedAccessors)
- (void)addZoomLevelsObject:(NSManagedObject *)value;
- (void)removeZoomLevelsObject:(NSManagedObject *)value;
- (void)addZoomLevels:(NSSet *)value;
- (void)removeZoomLevels:(NSSet *)value;

@end

