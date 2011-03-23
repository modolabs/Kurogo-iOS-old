/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import "MapZoomLevel.h"
#import "TileServerManager.h"

@implementation MapTile

- (id)initWithFrame:(MKMapRect)frame path:(NSString *)path {
    self = [super init];
    if (self) {
        _frame = frame;
        _path = path;
    }
    return self;
}

@synthesize path = _path, frame = _frame;

@end


@implementation MapZoomLevel

//static NSString *s_tileCachePath = nil;

@synthesize level, resolution, scale, maxCol, maxRow, minCol, minRow, zoomScale;

- (CGSize)totalSizeInPixels {
    CGSize size;
    size.width = [self tilesPerCol] * [TileServerManager tileWidth] * zoomScale;
    size.height = [self tilesPerCol] * [TileServerManager tileHeight] * zoomScale;
    return size;
}

//- (MapTile)tileForScreenPixel:(CGPoint)pixel {
//    MapTile tile;
//    tile.col = (pixel.x * zoomScale / [TileServerManager tileWidth]) + minCol;
//    tile.row = (pixel.y * zoomScale / [TileServerManager tileHeight]) + minRow;
//    return tile;
//}

+ (NSString *)tileCachePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* cachePath = [paths objectAtIndex:0];
    return [cachePath stringByAppendingPathComponent:@"tile"];
}

- (NSString *)pathForTileAtRow:(int)row col:(int)col {
    return [[MapZoomLevel tileCachePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d-%d-%d", self.level, row, col]];
}
/*
- (MapTile *)tileForMapPoint:(MKMapPoint)mapPoint {
    NSLog(@"mappoint: %.1f, %.1f", mapPoint.x, mapPoint.y);
    
    // TODO: for web mercator projections we don't need to do conversion at all,
    // just use ratio of mapPoint.x to MKMapSizeWorld.x and same for y

    // get everything in terms of tile server's coordinate system.
    CGPoint projPoint = [TileServerManager projectedPointForMapPoint:mapPoint];
    NSInteger col = round((projPoint.x - [TileServerManager originX]) / [TileServerManager tileWidth]) / self.resolution;
    NSInteger row = round(([TileServerManager originY] - projPoint.y) / [TileServerManager tileHeight]) / self.resolution;
    
    CGPoint tileOrigin = CGPointMake(col * self.resolution * [TileServerManager tileWidth] + [TileServerManager originX],
                                     row * self.resolution * [TileServerManager tileHeight] + [TileServerManager originY]);

    // convert back to MapKit coordinate system
    MKMapPoint origin = [TileServerManager mapPointForProjectedPoint:tileOrigin];
    tileOrigin.x += self.resolution * [TileServerManager tileWidth];
    tileOrigin.y += self.resolution * [TileServerManager tileHeight];
    MKMapPoint bottomRight = [TileServerManager mapPointForProjectedPoint:tileOrigin];
    MKMapRect rect = MKMapRectMake(origin.x, origin.y, bottomRight.x - origin.x, bottomRight.y - origin.y);

    NSLog(@"tile: %d, %d", col, row);
    
    MapTile *tile = [[[MapTile alloc] init] autorelease];
    tile.path = [self pathForTileAtRow:row col:col];
    tile.frame = rect;
     
    if (![[NSFileManager defaultManager] fileExistsAtPath:tile.path]) {
		//KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
        //[appDelegate showNetworkActivityIndicator];
        NSString* sUrl = [NSString stringWithFormat:@"%@/maptile/%d/%d/%d", MITMobileWebAPIURLString, level, row, col];
        NSURL* url = [NSURL URLWithString:sUrl];
        NSLog(@"requesting from %@", sUrl);
        
		NSURLRequest* request = [[NSURLRequest alloc] initWithURL:url];
		
		NSError* error = nil;
		NSURLResponse* response = nil;
		NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (data && ![[NSFileManager defaultManager] fileExistsAtPath:[MapZoomLevel tileCachePath]]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:[MapZoomLevel tileCachePath] withIntermediateDirectories:NO attributes:nil error:&error];
        }
        [[NSFileManager defaultManager] createFileAtPath:tile.path contents:data attributes:nil];
        
        //[appDelegate hideNetworkActivityIndicator];
		[request release];
    }
    
    //tile.row = [self tilesPerRow] * (int)floor(projPoint.y / [TileServerManager meridianLengthInProjectedUnits]);
    return tile;
}
*/
- (MapTile *)tileForRow:(int)row col:(int)col {
    CGPoint tileOrigin = CGPointMake(col * self.resolution * [TileServerManager tileWidth] + [TileServerManager originX],
                                     [TileServerManager originY] - row * self.resolution * [TileServerManager tileHeight]);
    DLog(@"tileorigin: %.1f %.1f", tileOrigin.x, tileOrigin.y);
    
    MKMapPoint origin = [TileServerManager mapPointForProjectedPoint:tileOrigin];
    tileOrigin.x += self.resolution * [TileServerManager tileWidth];
    tileOrigin.y += self.resolution * [TileServerManager tileHeight];
    MKMapPoint bottomRight = [TileServerManager mapPointForProjectedPoint:tileOrigin];
    MKMapRect rect = MKMapRectMake(origin.x, origin.y, bottomRight.x - origin.x, origin.y - bottomRight.y);
    DLog(@"assigned tile to rect: %.1f %.1f %.1f %.1f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    DLog(@"tile: %d, %d", col, row);
    
    MapTile *tile = [[[MapTile alloc] initWithFrame:rect path:[self pathForTileAtRow:row col:col]] autorelease];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:tile.path]) {
        DLog(@"%@", tile.path);
		//KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
        //[appDelegate showNetworkActivityIndicator];
        NSString* sUrl = [NSString stringWithFormat:@"%@/maptile/%d/%d/%d", MITMobileWebAPIURLString, level, row, col];
        NSURL* url = [NSURL URLWithString:sUrl];
        DLog(@"requesting from %@", sUrl);
        
		NSURLRequest* request = [[NSURLRequest alloc] initWithURL:url];
		
		NSError* error = nil;
		NSURLResponse* response = nil;
		NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:[MapZoomLevel tileCachePath]]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:[MapZoomLevel tileCachePath] withIntermediateDirectories:NO attributes:nil error:&error];
        }
        [[NSFileManager defaultManager] createFileAtPath:tile.path contents:data attributes:nil];
        
        //[appDelegate hideNetworkActivityIndicator];
		[request release];
    } else {
        DLog(@"found tile at %@", tile.path);
        DLog(@"%@", [NSData dataWithContentsOfFile:tile.path]);
    }
    
    //tile.row = [self tilesPerRow] * (int)floor(projPoint.y / [TileServerManager meridianLengthInProjectedUnits]);
    return tile;
}

- (NSArray *)tilesForMapRect:(MKMapRect)mapRect {
    DLog(@"tilesForMapRect: %.1f %.1f %.1f %.1f", mapRect.origin.x, mapRect.origin.y, mapRect.size.width, mapRect.size.height);

    // get everything in tile server's coordinate system
    CGPoint startPoint = [TileServerManager projectedPointForMapPoint:mapRect.origin];
    NSInteger startCol = round((startPoint.x - [TileServerManager originX]) / [TileServerManager tileWidth]) / self.resolution;
    NSInteger startRow = round(([TileServerManager originY] - startPoint.y) / [TileServerManager tileHeight]) / self.resolution;

    CGPoint endPoint = [TileServerManager projectedPointForMapPoint:MKMapPointMake(mapRect.origin.x + mapRect.size.width, mapRect.origin.y + mapRect.size.height)];
    NSInteger endCol = round((endPoint.x - [TileServerManager originX]) / [TileServerManager tileWidth]) / self.resolution;
    NSInteger endRow = round(([TileServerManager originY] - endPoint.y) / [TileServerManager tileHeight]) / self.resolution;

    DLog(@"startpoint: %.1f %.1f; endpoint: %.1f %.1f", startPoint.x, startPoint.y, endPoint.x, endPoint.y);

    NSMutableArray *tiles = [NSMutableArray arrayWithCapacity:(endRow - startRow + 1) * (endCol - startCol + 1)];
    for (NSInteger row = startRow; row <= endRow; row++) {
        for (NSInteger col = startCol; col <= endCol; col++) {
            MapTile *tile = [self tileForRow:row col:col];
            [tiles addObject:tile];
        }
    }
    return [NSArray arrayWithArray:tiles];
}

- (NSInteger)tilesPerRow {
    return maxRow - minRow + 1;
}

- (NSInteger)tilesPerCol {
    return maxCol - minCol + 1;
}

/*
- (NSInteger)pixelsPerRow {
    return round([self tilesPerRow] * [self.tileServer.tileWidth intValue] * [self.zoomScale doubleValue]);
}

- (NSInteger)pixelsPerCol {
    return round([self tilesPerCol] * [self.tileServer.tileHeight intValue] * [self.zoomScale doubleValue]);
}



- (NSInteger)tileRowForScreenPixelY:(CGFloat)y {    
    return floor(y * zoomScale / [TileServerManager tileHeight]) + minRow;
}

- (NSInteger)tileColForScreenPixelX:(CGFloat)x {
    return floor(x * zoomScale / [TileServerManager tileWidth]) + minCol;
}


- (CGFloat)circumferenceInPixels {
    CGFloat c = [self.tileServer circumferenceInProjectedUnits];
    return floor(c / [self.resolution doubleValue]);
}

- (CGFloat)radiusInPixels {
    return [self circumferenceInPixels] / (2 * M_PI);
}

#pragma mark Conversions between projected units and pixels for web mercator projection

- (CGPoint)pixelPointForProjectedCoord:(CGPoint)projected {
    CGPoint pixel;
    pixel.x = projected.x / resolution;
    pixel.y = projected.y / resolution;
    return pixel;
}

- (CGPoint)projectedCoordForPixelPoint:(CGPoint)pixel {
    CGPoint projected;
    projected.x = pixel.x * resolution;
    projected.y = pixel.y * resolution;
    return projected;
}
 
*/

@end
