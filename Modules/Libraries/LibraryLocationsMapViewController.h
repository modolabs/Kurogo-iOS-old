//
//  LibraryLocationsMapViewController.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/19/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Library.h"
#import "LibraryDataManager.h"

@interface LibraryLocationsMapViewController : UIViewController <MKMapViewDelegate, LibraryDataManagerDelegate> {
	
	MKMapView * mapView;
	NSArray * allLibraries;
	
    // TODO: this whole view controller class does not need to exist
    // since whoever the following navController points to could just
    // create and refer to their own mapView
	UIViewController * navController;
}

@property (nonatomic, retain) UIViewController * navController;
@property (nonatomic, retain) MKMapView * mapView;
@property BOOL showingOpenOnly;

-(id) initWithMapViewFrame:(CGRect) frame;

- (MKCoordinateRegion)regionForAnnotations:(NSArray *)annotations;

- (BOOL)mapView:(MKMapView *)_mapView didUpdateUserLocation:(MKUserLocation *)userLocation;

-(void) setAllLibraryLocations:(NSArray *) libraries;

@end
