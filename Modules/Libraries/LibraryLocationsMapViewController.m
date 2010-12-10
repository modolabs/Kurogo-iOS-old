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
#import "ItemAvailabilityLibraryAnnotation.h"


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
	self.mapView.delegate = nil;
	self.mapView = nil;
}



-(void) setAllLibraryLocations:(NSArray *) libraries{
	allLibraries = libraries;
	
	for (int i=0; i< [[self.mapView annotations] count]; i++)
		[self.mapView removeAnnotation:[[self.mapView annotations] objectAtIndex:i]];
	
	
	for (int index=0; index < [allLibraries count]; index++){
		Library *lib = [allLibraries objectAtIndex:index];
		
		LibraryAnnotation *annotation = [[LibraryAnnotation alloc] initWithLibrary:lib];
		
		[mapView addAnnotation:annotation];
	}
}


-(void) setAllAvailabilityLibraryLocations:(NSDictionary *)displayNameAndLibraries{
	
	for (int i=0; i< [[self.mapView annotations] count]; i++)
		[self.mapView removeAnnotation:[[self.mapView annotations] objectAtIndex:i]];
	
	
	//NSMutableArray * tempArray = [[NSMutableArray alloc] init];
	for(int index=0; index < [[displayNameAndLibraries allKeys] count]; index++){
		
		NSString * displayName = [[displayNameAndLibraries allKeys] objectAtIndex:index];
		Library * tempLib = [displayNameAndLibraries objectForKey:displayName];
		
		//[tempArray insertObject:tempLib atIndex:index];
		
		ItemAvailabilityLibraryAnnotation * annotation = [[ItemAvailabilityLibraryAnnotation alloc]
														  initWithRepoName:displayName 
														  identityTag:tempLib.identityTag 
														  type:tempLib.type 
														  lib:tempLib];
		
		[mapView addAnnotation:annotation];
		
	}
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
	
	else if ([annotation isKindOfClass:[ItemAvailabilityLibraryAnnotation class]]) 
	{
		annotationView = [[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"gufidfdlefdfdsfg"] autorelease];
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

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
	if ([view.annotation isKindOfClass:[LibraryAnnotation class]]) {
		
		LibraryDetailViewController *vc = [[LibraryDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
		
		apiRequest = [[JSONAPIRequest alloc] initWithJSONAPIDelegate:vc];
		
		NSArray * tempArray;
		
		if (showingOpenOnly == NO)
			tempArray = allLibraries;
		else {
			tempArray = opeLibraries;
		}
		
		Library * lib = (Library *)((LibraryAnnotation *)view.annotation).library;
		vc.lib = [lib retain];
		
		if ([lib.type isEqualToString:@"archive"])
			vc.title = @"Archive Detail";
		
		else
			vc.title = @"Library Detail";
		
		int indexSelected = 0;
		int tempIndex = 0;
		for(Library * libTemp in tempArray){
			if (([lib.name isEqualToString:libTemp.name]) && ([lib.identityTag isEqualToString:libTemp.identityTag]))
				indexSelected = tempIndex;
			
			tempIndex++;				
		}
		
		vc.otherLibraries = [tempArray retain];
		vc.currentlyDisplayingLibraryAtIndex = indexSelected;
		
		NSString * libOrArchive;
		
		if ([lib.type isEqualToString:@"archive"])
			libOrArchive = @"archivedetail";
		
		else {
			libOrArchive = @"libdetail";
		}
		
		
		if ([apiRequest requestObjectFromModule:@"libraries" 
										command:libOrArchive
									 parameters:[NSDictionary dictionaryWithObjectsAndKeys:lib.identityTag, @"id", lib.name, @"name", nil]])
		{
			[self.navController.navigationController pushViewController:vc animated:YES];
		}
		else {
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
																message:@"Could not connect to the server" 
															   delegate:self 
													  cancelButtonTitle:@"OK" 
													  otherButtonTitles:nil];
			[alertView show];
			[alertView release];
		}
		
		[vc release];
	}
}





@end
