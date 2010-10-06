#import "RouteMapViewController.h"
#import "ShuttleStopMapAnnotation.h"
#import "ShuttleStopViewController.h"
#import "ShuttleStop.h"
#import "ShuttleLocation.h"
#import "MITUIConstants.h"

#define DEGREES_TO_RADIANS(__ANGLE__) ((__ANGLE__) / 180.0 * M_PI)

// calculated for google maps projection in harvard square vicinity
#define NAUTICAL_MILES_PER_DEGREE_LATLON 46.196

@interface RouteMapViewController(Private)

// add the shuttles based on self.route.vehicleLocations
-(void) addShuttles;

// remove shuttles that are listed in self.route.vehicleLocations
-(void) removeShuttles;

// update the stop annotations based on the routeInfo
-(void) updateUpcomingStops;

-(void) updateStopAnnotation:(ShuttleStopMapAnnotation*)annotation;

-(MKCoordinateRegion) regionForRoute;

- (void)addTranslocLogo;

@end

@implementation RouteMapViewController
@synthesize mapView = _mapView;
@synthesize route = _route;
//@synthesize routeInfo = _routeInfo;
@synthesize parentViewController = _MITParentViewController;

@synthesize routeLine;
@synthesize routeLineView;



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.

- (void)viewDidLoad {
	
    [super viewDidLoad];
	[self addLoadingIndicator];
	hasStopInfoForMap == NO;
	hasNarrowedRegion = NO;
	[self fallBackViewDidLoad];
}

-(void)fallBackViewDidLoad {
	self.mapView.delegate = self;
	self.mapView.scrollEnabled = YES;
	
	hasNarrowedRegion = NO;
	
	_largeStopImage = [[UIImage imageNamed:@"shuttles/map_pin_shuttle_stop_complete.png"] retain];
	_largeUpcomingStopImage = [[UIImage imageNamed:@"shuttles/pin_shuttle_stop_complete_next.png"] retain];
	_smallStopImage = [[UIImage imageNamed:@"shuttles/shuttle-stop-dot.png"] retain];
	_smallUpcomingStopImage = [[UIImage imageNamed:@"shuttles/shuttle-stop-dot-next.png"] retain];
	
	//_scrim.frame = CGRectMake(_scrim.frame.origin.x, _scrim.frame.origin.y, _scrim.frame.size.width, 53.0);
	
	[self refreshRouteTitleInfo];
	self.title = NSLocalizedString(@"Route", nil);	
	
	/*if ([self.route.pathLocations count]) {
		[self narrowRegion];
	}*/
	if ([self.route.pathLocations count]) {
	 //[self narrowRegion];
	 }
	else {
		hasStopInfoForMap = NO;
		
		
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
		[self setRouteOverLayBounds:center latDelta:latDelta lonDelta:lonDelta];
		hasNarrowedRegion = NO;
		
	}
	
	
	
	// get the extended route info
	[[ShuttleDataManager sharedDataManager] registerDelegate:self];
	[[ShuttleDataManager sharedDataManager] requestRoute:self.route.routeID];
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
																							target:self
																							action:@selector(pollShuttleLocations)] autorelease];
	
	[self.mapView setShowsUserLocation:YES];
	self.mapView.hidden = YES;
	
    logoView = nil;
}

- (void)addTranslocLogo
{
    if (logoView == nil) {
        UIImage *im = [[UIImage imageNamed:@"shuttles/shuttle-transloc.png"] retain];
        UIImageView * logoImView = [[[UIImageView alloc] initWithImage:im] retain];
        logoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, logoImView.frame.size.width, logoImView.frame.size.height)];
        logoView.backgroundColor = [UIColor clearColor];
        [logoView addSubview:logoImView];
        [self.view addSubview:logoView];
    }
    
    CGPoint logoOrigin = CGPointMake(self.view.frame.size.width - logoView.frame.size.width - 10,
                                     self.view.frame.size.height - logoView.frame.size.height - 10);
    
    logoView.frame = CGRectMake(logoOrigin.x, logoOrigin.y, logoView.frame.size.width, logoView.frame.size.height);

	[self.view bringSubviewToFront:logoView];
}

-(void)narrowRegion {
	//[self.mapView addRoute:self.route];
	
	if ([self.route.pathLocations count]) {
		self.mapView.region = [self regionForRoute];
		hasStopInfoForMap = YES;
		//[self drawRect];
		[self assignRoutePoints];
		hasNarrowedRegion = YES;
	}
}


-(void)assignRoutePoints {
	MKMapPoint* pointArr = malloc(sizeof(CLLocationCoordinate2D) * self.route.pathLocations.count);
	for(int idx = 0; idx < self.route.pathLocations.count; idx++)
	{
		CLLocation* location = [self.route.pathLocations objectAtIndex:idx];
		CLLocationCoordinate2D coordinate = location.coordinate;
		MKMapPoint point = MKMapPointForCoordinate(coordinate);
		//CGPoint point = [_mapView convertCoordinate:location.coordinate toPointToView:self.mapView];
	
		
		pointArr[idx] = point;
	}
	
	// create the polyline based on the array of points. 
		self.routeLine = [MKPolyline polylineWithPoints:pointArr count:self.route.pathLocations.count];
		free(pointArr);
		
		
		if (nil != self.routeLine) {
			[self.mapView addOverlay:self.routeLine];
		}
}

-(void)setRouteOverLayBounds:(CLLocationCoordinate2D)center latDelta:(double)latDelta  lonDelta:(double) lonDelta {	
	routeRect = MKMapRectMake(center.latitude - latDelta, center.longitude - lonDelta, 2*latDelta, 2*lonDelta);
	return;
}
							  

-(void)selectAnnon:(id <MKAnnotation>)annotation {
	
	// determine the region for the route and zoom to that region
	CLLocationCoordinate2D coordinate = annotation.coordinate;
	
	CLLocationCoordinate2D center;
	center.latitude = coordinate.latitude; 
	center.longitude = coordinate.longitude; 
	
	double latDelta = 0.002;
	double lonDelta = 0.002;
	
	MKCoordinateSpan span = MKCoordinateSpanMake(latDelta, lonDelta);
	
	MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
	
	[self.mapView setRegion:region animated:YES];	
	[self.mapView selectAnnotation:annotation animated:YES];

}

-(void)refreshRouteTitleInfo {
	_routeTitleLabel.text = _route.title;
	_routeTitleLabel.font = [UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE - 1];
	_routeStatusLabel.text = [_route trackingStatus];    
}

-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[[ShuttleDataManager sharedDataManager] unregisterDelegate:self];
	if ([_pollingTimer isValid]) {
		[_pollingTimer invalidate];
	}
	[_pollingTimer release];
	_pollingTimer = nil;
}

-(void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self fallBackViewDidLoad];
	
	// make sure its registered. 
	[[ShuttleDataManager sharedDataManager] registerDelegate:self];
    
	// start polling for new vehicle locations every 10 seconds. 
	_pollingTimer = [[NSTimer scheduledTimerWithTimeInterval:2
													  target:self 
													selector:@selector(pollShuttleLocations)
													userInfo:nil 
													 repeats:YES] retain];
    
}

-(void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self becomeFirstResponder];
	
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    //[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


- (void)dealloc {
	[_smallStopImage release];
	[_smallUpcomingStopImage release];
	[_largeStopImage release];
	[_largeUpcomingStopImage release];
	_mapView.delegate = nil;
	[_mapView release];
	[_routeStops release];
	[_gpsButton release];
	[_routeTitleLabel release];
	[_routeStatusLabel release];
    [logoView release];
    
    [ShuttleLocation clearAllMarkerImages];
    
	self.route = nil;
	//self.routeInfo = nil;
	self.parentViewController = nil;
	
	self.routeLine = nil;
	self.routeLineView = nil;
	
	
    [super dealloc];
}

-(void) viewDidUnload
{
    [logoView release];
    logoView = nil;
    
	[super viewDidUnload];
	
	/*[_smallStopImage release];
	[_smallUpcomingStopImage release];
	[_largeStopImage release];
	[_largeUpcomingStopImage release];
	_mapView.delegate = nil;
	[_mapView release];
	[_routeStops release];
	[_gpsButton release];
	[_routeTitleLabel release];
	[_routeStatusLabel release];
	
	self.route = nil;
	//self.routeInfo = nil;
	self.parentViewController = nil;
	
	self.routeLine = nil;
	self.routeLineView = nil;*/
}
/*

-(void) setRouteInfo:(ShuttleRoute *) shuttleRoute
{
    if (_routeInfo != shuttleRoute) {
        [_routeInfo release];
        _routeInfo = [shuttleRoute retain];
    }
	
	[_routeStops release];
	_routeStops = [[NSMutableDictionary dictionaryWithCapacity:shuttleRoute.stops.count] retain];
	

	for (ShuttleStop* stop in shuttleRoute.stops) {
		[_routeStops setObject:stop forKey:stop.stopID];
	}
	
	// add the overlay to the map
	if (nil != self.routeLine) {
		[self.mapView addOverlay:self.routeLine];
	}
	
	// for each of the annotations in our route, retrieve subtitles, which in this case is the next time at stop
	for (ShuttleStopMapAnnotation* annotation in self.route.annotations) 
	{
		ShuttleStop* stop = [_routeStops objectForKey:annotation.shuttleStop.stopID];
		if(nil != stop)
		{
			//NSDate* nextScheduled = [NSDate dateWithTimeIntervalSince1970:stop.nextScheduled];
			//NSTimeInterval intervalTillStop = [nextScheduled timeIntervalSinceDate:[NSDate date]];
			
			//if (intervalTillStop > 0) {
			//	NSString* subtitle = [NSString stringWithFormat:@"Arriving in %d minutes", (int)(intervalTillStop / 60)];
			//	[annotation setSubtitle:subtitle];
			//}
			
			if (stop.upcoming) {
				NSString* subtitle = [NSString stringWithFormat:@"Arriving Next"];
				[annotation setSubtitle:subtitle];
			}
			else {
				NSString* subtitle = [NSString stringWithFormat:@""];
				[annotation setSubtitle:subtitle];
			}

				
		}
	}
	
	// tell the map to refresh whatever its current callout is. 
	//[_mapView refreshCallout];
}
*/

-(MKCoordinateRegion) regionForRoute
{
	
	// determine the region for the route and zoom to that region
	double minLat = 90;
	double maxLat = -90;
	double minLon = 180;
	double maxLon = -180;
	
	for (CLLocation* location in self.route.pathLocations) {
		CLLocationCoordinate2D coordinate = location.coordinate;
		if (coordinate.latitude < minLat) {
			minLat = coordinate.latitude;
		}
		if (coordinate.latitude > maxLat) {
			maxLat = coordinate.latitude;
		}
		if(coordinate.longitude < minLon) {
			minLon = coordinate.longitude;
		}
		if (coordinate.longitude > maxLon) {
			maxLon = coordinate.longitude;
		}
	}
	
	CLLocationCoordinate2D center;
	center.latitude = minLat + (maxLat - minLat) / 2;
	center.longitude = minLon + (maxLon - minLon) / 2;
	
	double latDelta = maxLat - minLat + 0.0001;
	double lonDelta = maxLon - minLon + 0.0001;
	
	//MKCoordinateSpan span = MKCoordinateSpanMake(latDelta + latDelta / 4, lonDelta + lonDelta / 4);
	//MKCoordinateSpan span = MKCoordinateSpanMake(latDelta, 1.1*lonDelta);
	
	//MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
	
	MKCoordinateSpan span = {latitudeDelta: latDelta, longitudeDelta: lonDelta};
	MKCoordinateRegion region = {center, span};
	
	region.span.latitudeDelta = latDelta;
	region.span.longitudeDelta = lonDelta;
	
	[self setRouteOverLayBounds:center latDelta:latDelta lonDelta:lonDelta];
	return region;
}

-(void) pollShuttleLocations
{
	[[ShuttleDataManager sharedDataManager] requestRoute:self.route.routeID];
}

-(void) removeShuttles
{
	[_mapView removeAnnotations:_vehicleAnnotations];
	//[_mapView removeAnnotations:_route.annotations];
	[_vehicleAnnotations release];
	_vehicleAnnotations = nil;
}

-(void) addShuttles
{
    
    [_oldVehicleAnnotations release];
    _oldVehicleAnnotations = [_vehicleAnnotations copy];
    
	_vehicleAnnotations = [[NSArray arrayWithArray:self.route.vehicleLocations] retain];
    
    // replace new annotations' starting coordinates with old annotations' ending coords
    for (ShuttleLocation *anOldLocation in _oldVehicleAnnotations) {
        for (ShuttleLocation *aNewLocation in _vehicleAnnotations) {
            if (anOldLocation.vehicleId == aNewLocation.vehicleId) {
                aNewLocation.coordinate = anOldLocation.endCoordinate;
            }
        }
    }
    
	[_mapView addAnnotations:_vehicleAnnotations];
    [_mapView performSelector:@selector(removeAnnotations:) withObject:_oldVehicleAnnotations afterDelay:0.2];
}

-(void) updateUpcomingStops
{
	for(ShuttleStopMapAnnotation* annotation in _route.annotations) 
	{
		ShuttleStop* stopInfo = [_routeStops objectForKey:annotation.shuttleStop.stopID];
		
		//ShuttleRoute *info = self.routeInfo;
		//if (info.upcoming != annotation.shuttleStop.upcoming) 
		//if ([info.nextStopId isEqualToString:stopInfo.stopID])
		if ([self.route.nextStopId isEqualToString:stopInfo.stopID])
		{
			annotation.shuttleStop.upcoming = YES; //info.upcoming;
			[self updateStopAnnotation:annotation];
		} 
		
		[self updateStopAnnotation:annotation];
	}
}

-(void) updateStopAnnotation:(ShuttleStopMapAnnotation*)annotation
{
	[self.mapView addAnnotation:annotation];
}

#pragma mark User actions
-(IBAction) gpsTouched:(id)sender
{
	//_mapView.centerCoordinate = _mapView.userLocation.location.coordinate;
	
	//_mapView.stayCenteredOnUserLocation = !_mapView.stayCenteredOnUserLocation;
	
	//NSString *bgImageName = [NSString stringWithFormat:@"scrim-button-background%@.png", _mapView.stayCenteredOnUserLocation ? @"-highlighted" : @""];
	//[_gpsButton setBackgroundImage:[UIImage imageNamed:bgImageName] forState:UIControlStateNormal];
	
	
	double minLat = _mapView.centerCoordinate.latitude - _mapView.region.span.latitudeDelta;
	double maxLat = _mapView.centerCoordinate.latitude + _mapView.region.span.latitudeDelta;
	
	double minLon = _mapView.centerCoordinate.longitude - _mapView.region.span.longitudeDelta;
	double maxLon = _mapView.centerCoordinate.longitude + _mapView.region.span.longitudeDelta;
	
	
	
	CLLocationCoordinate2D coordinate = _mapView.userLocation.location.coordinate;
	if (coordinate.latitude < minLat) {
		minLat = coordinate.latitude;
	}
	if (coordinate.latitude > maxLat) {
		maxLat = coordinate.latitude;
	}
	if(coordinate.longitude < minLon) {
		minLon = coordinate.longitude;
	}
	if (coordinate.longitude > maxLon) {
		maxLon = coordinate.longitude;
	}
	
	
	CLLocationCoordinate2D center;
	center.latitude = minLat + (maxLat - minLat) / 2;
	center.longitude = minLon + (maxLon - minLon) / 2;
	
	double latDelta = maxLat - minLat;
	double lonDelta = maxLon - minLon; 
	
	
	MKCoordinateSpan span = {latitudeDelta: latDelta, longitudeDelta: lonDelta};
	MKCoordinateRegion region = {center, span};
	
	region.span.latitudeDelta = latDelta;
	region.span.longitudeDelta = lonDelta;
	
	self.mapView.region = region;

	return;
}

-(IBAction) refreshTouched:(id)sender
{
	//_gpsButton.style = UIBarButtonItemStyleBordered;
	[_gpsButton setBackgroundImage:[UIImage imageNamed:@"shuttles/scrim-button-background.png"] forState:UIControlStateNormal];
	//_mapView.stayCenteredOnUserLocation = NO;
	
	[_mapView setRegion:[self regionForRoute]];
}


#pragma mark MKMapViewDelegate


- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
	MKOverlayView* overlayView = nil;
	
	if(overlay == self.routeLine)
	{
		//if we have not yet created an overlay view for this overlay, create it now. 
		if(nil == self.routeLineView)
		{
			self.routeLineView = [[[MKPolylineView alloc] initWithPolyline:self.routeLine] autorelease];
			self.routeLineView.fillColor = [UIColor colorWithHexString:(NSString *)self.route.color];
			self.routeLineView.strokeColor = [UIColor colorWithHexString:(NSString *)self.route.color];
			self.routeLineView.lineWidth = 5;
		}
		
		overlayView = self.routeLineView;
		
	}
	
	return overlayView;
	
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	MKAnnotationView* annotationView = nil;
	
	if ([annotation isKindOfClass:[ShuttleStopMapAnnotation class]]) 
	{
		annotationView = [[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"gufileg"] autorelease];
		UIImage* pin = [UIImage imageNamed:@"shuttles/shuttle-stop-dot.png"];
		UIImageView* imageView = [[[UIImageView alloc] initWithImage:pin] autorelease];
		
		BOOL upComing = NO;
		if ([((ShuttleStopMapAnnotation *)annotation).shuttleStop.stopID isEqualToString:self.route.nextStopId]) {
			upComing = YES;
		}
		
		UIButton *myDetailButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		myDetailButton.frame = CGRectMake(0, 0, 23, 23);
		myDetailButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		myDetailButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
		// Set the button as the callout view
		annotationView.rightCalloutAccessoryView = myDetailButton;
		
		annotationView.frame = imageView.frame;
		//NSURL *url = [NSURL URLWithString:self.routeInfo.urlForStopMarker];
		NSURL *url = [NSURL URLWithString:self.route.urlForStopMarker];
		NSData *data = [NSData dataWithContentsOfURL:url];
		UIImage *stop = [[UIImage alloc] initWithData:data];
		UIImageView* stopView = [[[UIImageView alloc] initWithImage:stop] autorelease];
		annotationView.canShowCallout = YES;
		[annotationView addSubview:stopView];
		annotationView.backgroundColor = [UIColor clearColor];		
	}
	else if([annotation isKindOfClass:[ShuttleLocation class]])
	{
		ShuttleLocation* shuttleLocation = (ShuttleLocation*) annotation;

        UIImage *marker = [shuttleLocation image];
		if (marker != nil) {
            annotationView = [[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"asdf"] autorelease];
            UIImageView* markerView = [[[UIImageView alloc] initWithImage:marker] autorelease];

            // align the bottom of the image with where it's pointing
            markerView.center = CGPointMake(markerView.center.x - floor(markerView.frame.size.width / 2),
                                            markerView.center.y - markerView.frame.size.height);
            
            [annotationView addSubview:markerView];
            [[annotationView superview] bringSubviewToFront:annotationView];
        }
	}
	
	//[sampleView setNeedsDisplay];
	return annotationView;
	
}


- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
	for (MKAnnotationView * annView in views) {
		//MKAnnotation *annotation = annView.annotation;
		
		if ([annView.annotation isKindOfClass:[ShuttleStopMapAnnotation class]]) 
		{
			[[annView superview] sendSubviewToBack:annView];
		} else if ([annView.annotation isKindOfClass:[ShuttleLocation class]]) {
			[[annView superview] bringSubviewToFront:annView];
            
            ShuttleLocation *locationAnnotation = (ShuttleLocation *)annView.annotation;
            
            CGPoint startPoint = [mapView convertCoordinate:locationAnnotation.coordinate toPointToView:nil];
            CGPoint endPoint = [mapView convertCoordinate:locationAnnotation.endCoordinate toPointToView:nil];
            CGFloat dx = round(endPoint.x - startPoint.x);
            CGFloat dy = round(endPoint.y - startPoint.y);

            
            if (fabs(dx) + fabs(dy) > 0) {
                NSLog(@"vehicle %d dx: %.1f, dy: %.1f", locationAnnotation.vehicleId, dx, dy);
                
                [UIView beginAnimations:@"vehicle" context:NULL];
                [UIView setAnimationDuration:2.0];
                annView.frame = CGRectMake(annView.frame.origin.x + dx,
                                           annView.frame.origin.y + dy,
                                           annView.frame.size.width, annView.frame.size.height);
                [UIView commitAnimations];
            }       
            
            /*
            if (locationAnnotation.speed) {
                
                CGFloat distanceIn2Seconds = locationAnnotation.speed / (3600 / 2); // in nautical miles

                // create a coordinate x nautical miles away irrelevant of direction
                CLLocationCoordinate2D coordSameDistanceAway = CLLocationCoordinate2DMake(locationAnnotation.coordinate.latitude,
                                                                                          locationAnnotation.coordinate.longitude + distanceIn2Seconds / NAUTICAL_MILES_PER_DEGREE_LATLON);
                CGPoint startPoint = [mapView convertCoordinate:locationAnnotation.coordinate toPointToView:nil];
                CGPoint endPoint = [mapView convertCoordinate:coordSameDistanceAway toPointToView:nil];
                CGFloat distance = fabs(startPoint.x - endPoint.x);
                NSLog(@"distance in pixels: %.1f", distance);
                
                // 0 is north, 90 is east
                NSInteger headingInXYPlane = 90 - locationAnnotation.heading;
                CGFloat radians = DEGREES_TO_RADIANS(headingInXYPlane);
                CGFloat dy = round(-distance * sin(radians));
                CGFloat dx = round(distance * cos(radians));
                NSLog(@"dx: %.1f, dy: %.1f", dx, dy);
                
                [UIView beginAnimations:@"vehicle" context:NULL];
                [UIView setAnimationDuration:2.0];
                annView.frame = CGRectMake(annView.frame.origin.x + dx,
                                           annView.frame.origin.y + dy,
                                           annView.frame.size.width, annView.frame.size.height);
                [UIView commitAnimations];
            }
            */

		}
	}
	
}



- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
	if ([view.annotation isKindOfClass:[ShuttleStopMapAnnotation class]])
	{
		ShuttleStopViewController* shuttleStopVC = [[[ShuttleStopViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
		shuttleStopVC.shuttleStop = [(ShuttleStopMapAnnotation*)view.annotation shuttleStop];
		shuttleStopVC.annotation = (ShuttleStopMapAnnotation*)view.annotation;
		
		[self.navigationController pushViewController:shuttleStopVC animated:YES];
		shuttleStopVC.view;
		//[shuttleStopVC.mapButton addTarget:self action:@selector(showSelectedStop:) forControlEvents:UIControlEventTouchUpInside];
	}
}

-(void) showSelectedStop:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

-(void) annotationSelected:(id<MKAnnotation>)annotation {
	MITModuleURL *url = ((id<MITModuleURLContainer>)self.parentViewController).url;
	ShuttleStopMapAnnotation *stopAnnotation = (ShuttleStopMapAnnotation *)annotation;
	[url setPath:[NSString stringWithFormat:@"route-map/%@/%@", _route.routeID, stopAnnotation.shuttleStop.stopID] query:nil];
	[url setAsModulePath];
}

-(void) annotationCalloutDidDisappear {
	MITModuleURL *url = ((id<MITModuleURLContainer>)self.parentViewController).url;
	[url setPath:[NSString stringWithFormat:@"route-map/%@", _route.routeID] query:nil];
	[url setAsModulePath];
}

#pragma mark ShuttleDataManagerDelegate
// message sent when a shuttle route is received. If request fails, this is called with nil
-(void) routeInfoReceived:(ShuttleRoute*)shuttleRoute forRouteID:(NSString*)routeID
{
	if ([self.route.routeID isEqualToString:routeID])
	{
		if (!self.route.isRunning) {
			[_pollingTimer invalidate];
		}
		
		//[self removeShuttles];
		
		//self.routeInfo = shuttleRoute;
        self.route = shuttleRoute;
		
		//if (![self.mapView.routes count]) {
		//	[self.mapView addRoute:self.route];
		//	self.mapView.region = [self regionForRoute];
		//}
		
		[self addShuttles];
		[self updateUpcomingStops];
		[self.mapView setCenterCoordinate:self.mapView.region.center animated:NO];
	}
	
	
	/*if (hasStopInfoForMap == NO) {
		[self fallBackViewDidLoad];
		hasStopInfoForMap = YES;
	}*/
	
	if (hasNarrowedRegion == NO)
		[self narrowRegion];
	
	self.mapView.hidden = NO;
	[self removeLoadingIndicator];
    [self addTranslocLogo];
}

#pragma mark Shake functionality
- (BOOL)canBecomeFirstResponder {
	return YES;
}


-(void) motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
	if (motion == UIEventSubtypeMotionShake) {
		[self pollShuttleLocations];
	}
}



- (void)addLoadingIndicator
{
	if (loadingIndicator == nil) {
		static NSString *loadingString = @"Loading...";
		UIFont *loadingFont = [UIFont fontWithName:STANDARD_FONT size:17.0];
		CGSize stringSize = [loadingString sizeWithFont:loadingFont];
		
        CGFloat verticalPadding = self.view.frame.size.height/2 - 10;
        CGFloat horizontalPadding = self.view.frame.size.width/2 - 25;
        CGFloat horizontalSpacing = 15.0;
		// CGFloat cornerRadius = 8.0;
        
        UIActivityIndicatorViewStyle style = UIActivityIndicatorViewStyleGray;
		UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
		// spinny.center = CGPointMake(spinny.center.x + horizontalPadding, spinny.center.y + verticalPadding);
		spinny.center = CGPointMake(horizontalPadding, verticalPadding);
		[spinny startAnimating];
        
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(horizontalPadding + horizontalSpacing, verticalPadding -10, stringSize.width, stringSize.height + 2.0)];
		label.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
		label.text = loadingString;
		label.font = loadingFont;
		label.backgroundColor = [UIColor clearColor];
        
		//loadingIndicator = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, stringSize.width + spinny.frame.size.width + horizontalPadding * 2, stringSize.height + verticalPadding * 2)];
		loadingIndicator = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height)];
		//loadingIndicator = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300, 300)];
        //loadingIndicator.layer.cornerRadius = cornerRadius;
        //loadingIndicator.backgroundColor =[UIColor whiteColor];
		
		[loadingIndicator setBackgroundColor:[UIColor whiteColor]];
		[loadingIndicator addSubview:spinny];
		[spinny release];
		[loadingIndicator addSubview:label];
		[label release];
		
	}
	
	
	[self.view addSubview:loadingIndicator];
}

- (void)removeLoadingIndicator
{
	[loadingIndicator removeFromSuperview];
	[loadingIndicator release];
	loadingIndicator = nil;
	
}




@end
