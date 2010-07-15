#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "JSONAPIRequest.h"

@interface MapTileOverlay : NSObject <MKOverlay> {
    
    CLLocationCoordinate2D coordinate;
    MKMapRect boundingMapRect;

}

@end
