#import "MapTileOverlayView.h"
#import "TileServerManager.h"
#import "MapZoomLevel.h"


@implementation MapTileOverlayView

- (id)initWithOverlay:(id <MKOverlay>)overlay {
    if (self = [super initWithOverlay:overlay]) {
        NSLog(@"%@", [overlay description]);
    }
    return self;
}


// TODO: don't draw above certain zoomscale and outside certain maprect
/*
- (BOOL)canDrawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale {
   return [super canDrawMapRect:mapRect zoomScale:zoomScale];
}
*/

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context {
    
    NSArray *zoomLevels = [TileServerManager mapLevels];
    MapZoomLevel *theZoomLevel = nil;
    CGFloat scale;
    NSLog(@"looking for zoomscale %.8f", 1 / zoomScale);
    // TODO: find a more efficient way to get zoomLevel
    for (theZoomLevel in zoomLevels) {
        // keep iterating until we reach the max scale, or hit one scale larger
        scale = theZoomLevel.zoomScale;
        if (scale > zoomScale) {
            break;
        }
    }
    NSLog(@"map level is set to %d with scale %.8f", theZoomLevel.level, 1 / scale);
    
    NSArray *tiles = [theZoomLevel tilesForMapRect:mapRect];

    CGContextSetAlpha(context, 0.7);
    
    for (MapTile *tile in tiles) {
        
        //NSLog(@"maprect: %.1f %.1f %.1f %.1f", tile.frame.origin.x, tile.frame.origin.y, tile.frame.size.width, tile.frame.size.height);
        //NSLog(@"maprect: %.1f %.1f %.1f %.1f", mapRect.origin.x, mapRect.origin.y, mapRect.size.width, mapRect.size.height);
        CGRect rect = [self rectForMapRect:tile.frame];
        //NSLog(@"rect: %.1f %.1f %.1f %.1f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:tile.path];
        if (image == nil) {
            NSLog(@"image is nil");
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:tile.path error:&error];
        } else {
            CGContextSaveGState(context);
            CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
            //CGContextScaleCTM(context, 1/zoomScale, 1/zoomScale);
            CGContextScaleCTM(context, 2.5/scale, 2.5/scale);
            CGContextTranslateCTM(context, 0, image.size.height);
            CGContextScaleCTM(context, 1, -1);
            CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), [image CGImage]);
            CGContextRestoreGState(context);
        }
    }
    
    //MapTile aTile = [theZoomLevel tileForMapPoint:mapRect.origin];
    
    
}


/*
 - (void)setNeedsDisplayInMapRect:(MKMapRect)mapRect
 - (void)setNeedsDisplayInMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale
 */

@end