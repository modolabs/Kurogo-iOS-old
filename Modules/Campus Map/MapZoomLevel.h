#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
//#import "TileServerManager.h"

//@class MapTileServer;

//typedef struct { NSInteger col, row; } MapTile;

@interface MapTile : NSObject {
    NSString *_path;
    MKMapRect _frame;
}

@property (nonatomic, retain) NSString *path;
@property (nonatomic, assign) MKMapRect frame;

@end

@interface MapZoomLevel :  NSObject  
{
    NSInteger level;
    CGFloat resolution;
    CGFloat scale;
    NSInteger maxCol;
    NSInteger maxRow;
    NSInteger minCol;
    NSInteger minRow;
    MKZoomScale zoomScale;
}

//- (MapTile)tileForScreenPixel:(CGPoint)pixel;
- (CGSize)totalSizeInPixels;
- (NSInteger)tilesPerRow;
- (NSInteger)tilesPerCol;

- (MapTile *)tileForMapPoint:(MKMapPoint)mapPoint;

- (NSString *)pathForTileAtRow:(int)row col:(int)col;
- (NSArray *)tilesForMapRect:(MKMapRect)mapRect;

- (CGPoint)pixelPointForProjectedCoord:(CGPoint)projected;
- (CGPoint)projectedCoordForPixelPoint:(CGPoint)pixel;
/*
- (NSInteger)pixelsPerCol;
- (NSInteger)pixelsPerRow;
- (CGFloat)circumferenceInPixels;
- (CGFloat)radiusInPixels;
- (CGPoint)pixelPointForCoord:(CLLocationCoordinate2D)coord;
- (CLLocationCoordinate2D)coordForPixelPoint:(CGPoint)pixel;
- (NSInteger)tileRowForScreenPixelY:(CGFloat)y;
- (NSInteger)tileColForScreenPixelX:(CGFloat)x;
*/
@property (nonatomic, assign) NSInteger level;
@property (nonatomic, assign) CGFloat resolution;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) NSInteger maxCol;
@property (nonatomic, assign) NSInteger maxRow;
@property (nonatomic, assign) NSInteger minCol;
@property (nonatomic, assign) NSInteger minRow;
@property (nonatomic, assign) MKZoomScale zoomScale;

@end



