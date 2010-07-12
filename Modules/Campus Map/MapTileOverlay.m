#import "MapTileOverlay.h"
#import "TileServerManager.h"

#define kLastUpdatedKey @"last_updated"

@implementation MapTileOverlay

- (id)init {
    if (self = [super init]) {
		NSDictionary* dictionary = [NSDictionary dictionaryWithContentsOfFile:[MapTileOverlay mapTimestampFilename]];
		_mapTimestamp = [[dictionary objectForKey:kLastUpdatedKey] longLongValue];
		
		MITMobileWebAPI* api = [MITMobileWebAPI jsonLoadedDelegate:self];
		[api requestObject:[NSDictionary dictionaryWithObject:@"tilesupdated" forKey:@"command"] pathExtension:@"map"];
        
        CLLocationCoordinate2D nw = [TileServerManager northWestBoundary];
        CLLocationCoordinate2D se = [TileServerManager southEastBoundary];
        MKMapPoint mapNW = MKMapPointForCoordinate(nw);
        MKMapPoint mapSE = MKMapPointForCoordinate(se);
        boundingMapRect = MKMapRectMake(mapNW.x, mapSE.y, mapSE.x - mapNW.x, mapNW.y - mapSE.y);
        NSLog(@"initialized MapTileOverlay with bounding rect: %.1f %.1f %.1f %.1f");
        
    }
    return self;
}


- (CLLocationCoordinate2D)coordinate {
    return coordinate;
}

- (MKMapRect)boundingMapRect {
    return boundingMapRect;
}

//- (BOOL)intersectsMapRect:(MKMapRect)mapRect


+ (NSString*)pathForTileAtLevel:(int)level row:(int)row col:(int)col {
	NSString* tileCachePath = [MapTileOverlay tileCachePath];
	return [tileCachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d/%d/%d", level, row, col]];
}

+ (NSString *)tileCachePath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString* cachePath = [paths objectAtIndex:0];
	return [cachePath stringByAppendingPathComponent:@"tile"];
}

+ (NSString*)mapTimestampFilename
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* documentPath = [paths objectAtIndex:0];
	return [documentPath stringByAppendingPathComponent:@"mapTimestamp.plist"];	
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject {
	NSDictionary* dictionary = (NSDictionary*)JSONObject;
	long long newMapTimestamp = [[dictionary objectForKey:kLastUpdatedKey] longLongValue];
	
	if (YES) {// (newMapTimestamp > _mapTimestamp) {
		// store the new timestamp and wipe out the cache.
        NSLog(@"new map tiles found");
		[dictionary writeToFile:[MapTileOverlay mapTimestampFilename] atomically:YES];
		
		NSString* tileCachePath = [MapTileOverlay tileCachePath];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:tileCachePath]) {
            NSError* error = nil;
            if (![[NSFileManager defaultManager] removeItemAtPath:tileCachePath error:&error]) {
                NSLog(@"Error wiping out map cache: %@", error);
            }
        }
        
		// send a notification to any observers that the map cache was reset. 
		//[[NSNotificationCenter defaultCenter] postNotificationName:MapCacheReset object:self];
	}
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request {
	NSLog(@"Check tile update failed.");	
}

@end
