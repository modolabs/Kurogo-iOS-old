/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "JSONAPIRequest.h"

@interface MapTileOverlay : NSObject <MKOverlay> {
    
    CLLocationCoordinate2D coordinate;
    MKMapRect boundingMapRect;

}

@end
