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
//#import "JSONAPIRequest.h"
#import "LibraryDataManager.h"

@interface LibraryLocationsMapViewController : UIViewController <MKMapViewDelegate, LibraryDataManagerDelegate> {
	
	MKMapView * mapView;
	NSArray * allLibraries;
	NSMutableArray * opeLibraries;
	
	BOOL showingOpenOnly;
	
	//JSONAPIRequest * apiRequest;
	
	UIViewController * navController;
	
	NSDictionary * displayNameAndLibrariesDictionary;
    
    // true if we are looking at map of an item's available locations, false if we are looking at generic map
    BOOL isAvailabilityMap;

}

@property (nonatomic, retain) UIViewController * navController;
@property (nonatomic, retain) MKMapView * mapView;
@property BOOL showingOpenOnly;

-(id) initWithMapViewFrame:(CGRect) frame;

- (MKCoordinateRegion)regionForAnnotations:(NSArray *)annotations;

- (BOOL)mapView:(MKMapView *)_mapView didUpdateUserLocation:(MKUserLocation *)userLocation;

-(void) setAllLibraryLocations:(NSArray *) libraries;
//-(void) setAllAvailabilityLibraryLocations:(NSDictionary *)displayNameAndLibraries;

- (NSArray *)currentLibraries;

@end
