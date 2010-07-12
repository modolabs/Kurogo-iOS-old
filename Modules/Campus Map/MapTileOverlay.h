#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "MITMobileWebAPI.h"

@interface MapTileOverlay : NSObject <MKOverlay, JSONLoadedDelegate> {
    
    CLLocationCoordinate2D coordinate;
    MKMapRect boundingMapRect;
    long long _mapTimestamp;

}

+ (NSString*)mapTimestampFilename;
+ (NSString *)tileCachePath;

@end
