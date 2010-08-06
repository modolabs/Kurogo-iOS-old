#import "PolygonOverlay.h"
#import "TileServerManager.h"

@interface PolygonRing : NSObject {
    NSInteger _size;
    CLLocationCoordinate2D *_coordinates;
}

- (id)initWithPoints:(NSArray *)ringPoints;

@property (nonatomic, assign) NSInteger size;
@property (nonatomic, assign) CLLocationCoordinate2D *coordinates;

@end



@implementation PolygonOverlayView

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context {
    
    CGContextSetRGBFillColor(context, 0.9, 0.5, 0.6, 0.7);
    
    // thanks to Matt Gallagher at Cocoa with Love for
    // advice on how to draw polygons with inner rings
    // http://cocoawithlove.com/2010/05/5-ways-to-draw-2d-shape-with-hole-in.html
    // which incidentally is already how the arcgis server returns coordinates
    for (PolygonRing *aRing in ((PolygonOverlay *)self.overlay).rings) {
        CGPoint startPoint;
        for (NSInteger j = 0; j < aRing.size; j++) {
            MKMapPoint mapPoint = MKMapPointForCoordinate(aRing.coordinates[j]);
            CGPoint point = [self pointForMapPoint:mapPoint];
            if (j == 0) {
                startPoint = point;
                CGContextMoveToPoint(context, point.x, point.y);
            } else {
                CGContextAddLineToPoint(context, point.x, point.y);
            }
        }
        CGContextAddLineToPoint(context, startPoint.x, startPoint.y);
        CGContextClosePath(context);
    }
    
    CGContextFillPath(context);
}


@end


@implementation PolygonOverlay

@synthesize rings = _rings;

/* the "rings" array looks like the following
 * [
 *  [
 *   [ A0x, A0y ],
 *   [ B0x, B0y ],
 *   ...
 *  ],
 *  [
 *   [ A1x, A1y ],
 *   ...
 *  ],
 *  ...
 * ]
 * 
 * usually there is only one ring
 */
- (id)initWithRings:(NSArray *)rings {
    
    if (self = [super init]) {
        NSMutableArray *convertedRings = [NSMutableArray arrayWithCapacity:[rings count]];
        
        for (NSArray *ringPoints in rings) {
            PolygonRing *ring = [[PolygonRing alloc] initWithPoints:ringPoints];
            [convertedRings addObject:ring];
        }
        
        self.rings = [NSArray arrayWithArray:convertedRings];
        
        if ([self.rings count] > 0) {
            PolygonRing *outerRing = [self.rings objectAtIndex:0];
            
            CGFloat minLat = 90.0;
            CGFloat minLon = 180.0;
            CGFloat maxLat = -90.0;
            CGFloat maxLon = -180.0;
            
            CGFloat totalX = 0.0;
            CGFloat totalY = 0.0;
            
            for (NSInteger ringIndex = 0; ringIndex < outerRing.size; ringIndex++) {
                CLLocationCoordinate2D ringCoord = outerRing.coordinates[ringIndex];
                totalX += ringCoord.longitude;
                totalY += ringCoord.latitude;
                
                if (ringCoord.latitude < minLat)
                    minLat = ringCoord.latitude;
                if (ringCoord.latitude > maxLat)
                    maxLat = ringCoord.latitude;
                if (ringCoord.longitude < minLon)
                    minLon = ringCoord.longitude;
                if (ringCoord.longitude > maxLon)
                    maxLon = ringCoord.longitude;
            }
            
            _coordinate = CLLocationCoordinate2DMake(totalY / outerRing.size, totalX / outerRing.size);
            
            MKMapPoint topLeft = MKMapPointForCoordinate(CLLocationCoordinate2DMake(maxLat, minLon));
            MKMapPoint bottomRight = MKMapPointForCoordinate(CLLocationCoordinate2DMake(minLat, maxLon));
            
            _boundingMapRect = MKMapRectMake(topLeft.x, topLeft.y, bottomRight.x - topLeft.x, bottomRight.y - topLeft.y);
        }
    }
    return self;
}

- (CLLocationCoordinate2D)coordinate {
    return _coordinate;
}

- (MKMapRect)boundingMapRect {
    return _boundingMapRect;
}

- (NSString *)description {
    NSString *result = [NSString stringWithFormat:@"%@ (%d rings)", [super description], [_rings count]];
    return result;
}

@end


@implementation PolygonRing

@synthesize size = _size, coordinates = _coordinates;

/* we will only be initialized by the PolygonOverlay
 * which will pass "ringPoints" array like the following
 * [
 *  [ Ax, Ay ],
 *  [ Bx, By ],
 *  [ Cx, Cy ],
 *  [ Dx, Dy ],
 *  ...
 * ]
 *
 */
- (id)initWithPoints:(NSArray *)ringPoints {
    if (self = [super init]) {
        _size = [ringPoints count];
        _coordinates = malloc(sizeof(CLLocationCoordinate2D) * _size);
        for (NSInteger i = 0; i < _size; i++) {
            NSArray *pointArray = [ringPoints objectAtIndex:i];
            CGPoint point = CGPointMake([[pointArray objectAtIndex:0] doubleValue], [[pointArray objectAtIndex:1] doubleValue]);
            CLLocationCoordinate2D coord = [TileServerManager coordForProjectedPoint:point];
            _coordinates[i] = coord;
		}
    }
    return self;
}


- (void)dealloc {
    free(_coordinates);
    [super dealloc];
}

@end
