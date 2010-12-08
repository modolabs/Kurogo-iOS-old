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
#import "JSONAPIRequest.h"


@interface LibraryLocationsMapViewController : UIViewController <MKMapViewDelegate>{
	
	MKMapView * mapView;
	NSArray * allLibraries;
	NSMutableArray * opeLibraries;
	
	BOOL showingOpenOnly;
	
	JSONAPIRequest * apiRequest;
	
	UIViewController * navController;

}

@property (nonatomic, retain) UIViewController * navController;
@property (nonatomic, retain) MKMapView * mapView;
@property BOOL showingOpenOnly;

-(id) initWithMapViewFrame:(CGRect) frame;

- (MKCoordinateRegion)regionForAnnotations:(NSArray *)annotations;

- (BOOL)mapView:(MKMapView *)_mapView didUpdateUserLocation:(MKUserLocation *)userLocation;

-(void) setAllLibraryLocations:(NSArray *) libraries;
-(void) setOpenLibrariesLocations: (NSArray *) openLibraries;
-(void) addToOpenLibraries: (Library *) library;
-(void) removeFromOpenLibraries: (Library *) library;

-(void) addLibraryLocationOnMap: (Library *) library;



@end
