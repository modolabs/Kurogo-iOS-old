    //
//  LibraryLocationsMapViewController.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/19/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "LibraryLocationsMapViewController.h"
#import "Library.h"
#import "LibraryAnnotation.h"
#import "LibraryDetailViewController.h"
#import "LibraryAlias.h"

@implementation LibraryLocationsMapViewController
@synthesize mapView;
@synthesize showingOpenOnly;
@synthesize navController;

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
    [allLibraries release];
    
	self.mapView.delegate = nil;
	self.mapView = nil;

    [super dealloc];
}



-(void) setAllLibraryLocations:(NSArray *) libraries{
    [allLibraries release];
	allLibraries = [libraries retain];
    
    [self.mapView removeAnnotations:[self.mapView annotations]];
	
	for (int index=0; index < [allLibraries count]; index++){
		LibraryAlias *lib = [allLibraries objectAtIndex:index];
		
		LibraryAnnotation *annotation = [[LibraryAnnotation alloc] initWithLibrary:lib];
		
		[mapView addAnnotation:annotation];
	}
	
	mapView.region = [self regionForAnnotations:mapView.annotations];
}

#pragma mark MKMapViewDelegate


- (MKAnnotationView *)mapView:(MKMapView *)_mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	MKAnnotationView* annotationView = nil;
	
	if ([annotation isKindOfClass:[LibraryAnnotation class]]) 
	{
		annotationView = [[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"gufidfdleg"] autorelease];
		UIImage* pin = [UIImage imageNamed:@"maps/map_pin_complete.png"];
		UIImageView* imageView = [[[UIImageView alloc] initWithImage:pin] autorelease];
		
		
		UIButton *myDetailButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		myDetailButton.frame = CGRectMake(0, 0, 23, 23);
		myDetailButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		myDetailButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
		// Set the button as the callout view
		annotationView.rightCalloutAccessoryView = myDetailButton;
		
		annotationView.frame = imageView.frame;
		annotationView.canShowCallout = YES;
		[annotationView addSubview:imageView];
		annotationView.backgroundColor = [UIColor clearColor];		
	}
	return annotationView;
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
	return NO;
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
		
		if (([annotations count] > 1) && ((coordinate.latitude < 42.37) || (coordinate.latitude > 42.38)))
			continue;
		
		if (([annotations count] > 1) && ((coordinate.longitude < -71.12) || (coordinate.longitude > -71.11)))
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
        
        //if (latDelta < 0.002) latDelta = 0.002;
        //if (lonDelta < 0.002) lonDelta = 0.002;
		
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

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    LibraryDetailViewController *vc = [[LibraryDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    LibraryAlias * lib = (LibraryAlias *)((LibraryAnnotation *)view.annotation).libAlias;
    vc.lib = lib;
    
    if ([lib.library.type isEqualToString:@"archive"])
        vc.title = @"Archive Detail";
    
    else
        vc.title = @"Library Detail";
    
    int indexSelected = 0;
    int tempIndex = 0;
    for(LibraryAlias * libTemp in allLibraries){
        if ([lib.library.identityTag isEqualToString:libTemp.library.identityTag])
            indexSelected = tempIndex;
        
        tempIndex++;
    }
    
    vc.otherLibraries = allLibraries;
    vc.currentlyDisplayingLibraryAtIndex = indexSelected;
    
    [self.navController.navigationController pushViewController:vc animated:YES];
    
    [vc release];
}





@end
