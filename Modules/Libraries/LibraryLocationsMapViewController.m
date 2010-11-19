    //
//  LibraryLocationsMapViewController.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/19/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "LibraryLocationsMapViewController.h"


@implementation LibraryLocationsMapViewController
@synthesize mapView;
@synthesize showingOpenOnly;

-(id) initWithMapViewFrame:(CGRect) frame {
	
	self = [super init];
	
	
	if (self) {
		self.mapView = [[MKMapView alloc] initWithFrame:frame];
		self.mapView.scrollEnabled = YES;
		self.mapView.delegate = self;
	}
	
	return self;
}


-(void) viewDidLoad {
	
	if (self.showingOpenOnly != YES) {
		self.showingOpenOnly = NO;
	}
	

	
	CLLocationCoordinate2D center;
	center.latitude = 42.37640;
	center.longitude = -71.11660;
	
	double latDelta = 0.004;
	double lonDelta = 0.004; 
	
	
	MKCoordinateSpan span = {latitudeDelta: latDelta, longitudeDelta: lonDelta};
	MKCoordinateRegion region = {center, span};
	
	region.span.latitudeDelta = latDelta;
	region.span.longitudeDelta = lonDelta;
	
	self.mapView.region = region;
	
	[self.view addSubview:self.mapView];
	
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}



-(void) setAllLibraryLocations:(NSArray *) libraries{
}

-(void) addLibraryLocationOnMap: (Library *) library {
}

-(void) setOpenLibrariesLocations: (NSArray *) openLibraries{
}

-(void) addToOpenLibraries: (Library *) library {
}

-(void) removeFromOpenLibraries: (Library *) library {
}

#pragma mark MKMapViewDelegate


- (MKAnnotationView *)mapView:(MKMapView *)_mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	
}


- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
   	
}

- (BOOL)mapView:(MKMapView *)_mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    if (!mapView.showsUserLocation) {
		double lat = userLocation.coordinate.latitude;
		double lon = userLocation.coordinate.longitude;
		
		if ((lat > -180) && (lon > -180) && (lat < 180) && (lon < 180)) {
			mapView.region = MKCoordinateRegionMake(userLocation.coordinate, MKCoordinateSpanMake(0.001, 0.001));
			return YES;
		}
		return NO;
    }
}



- (void)mapView:(MKMapView *)_mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{

}

- (MKCoordinateRegion)regionForAnnotations:(NSArray *)annotations {
	
    MKCoordinateRegion region;
    
    double minLat = 90;
    double maxLat = -90;
    double minLon = 180;
    double maxLon = -180;
    
    // allow this function to handle MKAnnotationView
    // in addition to MKAnnotation objects by default
    BOOL isAnnotationView = NO;
    if ([annotations count]) {
        id object = [annotations objectAtIndex:0];
        if ([object isKindOfClass:[MKAnnotationView class]]) {
            isAnnotationView = YES;
        }
    }
	
    for (id object in annotations) {
        id<MKAnnotation> annotation = nil;
        if (isAnnotationView) {
            annotation = ((MKAnnotationView *)object).annotation;
        } else {
            annotation = (id<MKAnnotation>)object;
        }
		
        CLLocationCoordinate2D coordinate = annotation.coordinate;
        
        if (coordinate.latitude == 0 && coordinate.longitude == 0)
            continue;
        
        if (coordinate.latitude < minLat)
            minLat = coordinate.latitude;
        if (coordinate.latitude > maxLat)
            maxLat = coordinate.latitude;
        if (coordinate.longitude < minLon)
            minLon = coordinate.longitude;
        if (coordinate.longitude > maxLon)
            maxLon = coordinate.longitude;
    }
    
    if (maxLat != -90) {
        
        CLLocationCoordinate2D center;
        center.latitude = minLat + (maxLat - minLat) / 2;
        center.longitude = minLon + (maxLon - minLon) / 2;
        
        // create the span and region with a little padding
        double latDelta = maxLat - minLat;
        double lonDelta = maxLon - minLon;
        
        if (latDelta < 0.002) latDelta = 0.002;
        if (lonDelta < 0.002) lonDelta = 0.002;
		
        region = MKCoordinateRegionMake(center, MKCoordinateSpanMake(latDelta + latDelta / 4 , lonDelta + lonDelta / 4));        
    }
	else {
		CLLocationCoordinate2D center;
		center.latitude = 42.37640;
		center.longitude = -71.11660;
		
		double latDelta = 0.004;
		double lonDelta = 0.004; 
		
		
		MKCoordinateSpan span = {latitudeDelta: latDelta, longitudeDelta: lonDelta};
		MKCoordinateRegion regionToReturn = {center, span};
		
		regionToReturn.span.latitudeDelta = latDelta;
		regionToReturn.span.longitudeDelta = lonDelta;
		
		return regionToReturn;

	}

    
    return region;
}





@end
