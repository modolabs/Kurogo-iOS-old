#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "JSONAPIRequest.h"

@interface MapTileOverlay : NSObject <MKOverlay, JSONAPIDelegate> {
    
    CLLocationCoordinate2D coordinate;
    MKMapRect boundingMapRect;
    long long _mapTimestamp;

}

+ (NSString*)mapTimestampFilename;
+ (NSString *)tileCachePath;

@end
