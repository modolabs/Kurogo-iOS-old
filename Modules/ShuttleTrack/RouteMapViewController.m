#import "RouteMapViewController.h"
#import "ShuttleStopMapAnnotation.h"
#import "ShuttleStopViewController.h"
#import "ShuttleStop.h"
#import "ShuttleLocation.h"

#define DEGREES_TO_RADIANS(__ANGLE__) ((__ANGLE__) / 180.0 * M_PI)

@interface RouteMapViewController(Private)

// add the shuttles based on self.route.vehicleLocations
-(void) addShuttles;

// remove shuttles that are listed in self.route.vehicleLocations
-(void) removeShuttles;

// update the stop annotations based on the routeInfo
-(void) updateUpcomingStops;

-(void) updateStopAnnotation:(ShuttleStopMapAnnotation*)annotation;

-(MKCoordinateRegion) regionForRoute;

@end

@implementation RouteMapViewController
@synthesize mapView = _mapView;
@synthesize route = _route;
@synthesize routeInfo = _routeInfo;
@synthesize parentViewController = _MITParentViewController;

@synthesize routeLine;
@synthesize routeLineView;



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.

- (void)viewDidLoad {
	
    [super viewDidLoad];
	hasStopInfoForMap == NO;
	[self fallBackViewDidLoad];
	
	
	
}

-(void)fallBackViewDidLoad {
	self.mapView.delegate = self;
	self.mapView.scrollEnabled = YES;
	
	//sampleView = [[SampleViewClass initWithRoute:self.route.pathLocations mapView:self.mapView] autorelease];
	
	//sampleView = [[SampleViewClass alloc] initWithRoute:self.route.pathLocations mapView:self.mapView];
	//sampleView.userInteractionEnabled = NO;
	//sampleView.lineColor = [UIColor colorWithHexString:(NSString *)self.route.color];
	//[self.mapView addSubview:sampleView];
	
	
	//self.mapView.shouldNotDropPins = YES;
	
	_largeStopImage = [[UIImage imageNamed:@"map_pin_shuttle_stop_complete.png"] retain];
	_largeUpcomingStopImage = [[UIImage imageNamed:@"pin_shuttle_stop_complete_next.png"] retain];
	_smallStopImage = [[UIImage imageNamed:@"shuttle-stop-dot.png"] retain];
	_smallUpcomingStopImage = [[UIImage imageNamed:@"shuttle-stop-dot-next.png"] retain];
	
	//_scrim.frame = CGRectMake(_scrim.frame.origin.x, _scrim.frame.origin.y, _scrim.frame.size.width, 53.0);
	
	[self refreshRouteTitleInfo];
	self.title = NSLocalizedString(@"Route", nil);	
	
	[self.mapView setShowsUserLocation:YES];
	
	if ([self.route.pathLocations count]) {
		//[self.mapView addRoute:self.route];
		self.mapView.region = [self regionForRoute];
		hasStopInfoForMap = YES;
		//[self drawRect];
		[self assignRoutePoints];
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
		

		
	}
	
	
	
	// get the extended route info
	[[ShuttleDataManager sharedDataManager] registerDelegate:self];
	[[ShuttleDataManager sharedDataManager] requestRoute:self.route.routeID];
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
																							target:self
																							action:@selector(pollShuttleLocations)] autorelease];
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
	/*
	int index = 0;
	CLLocationDegrees latitude  = stop.latitude;
	CLLocationDegrees longitude = stop.longitude;
	
	
	// create our coordinate and add it to the correct spot in the array 
	CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
	
	MKMapPoint point = MKMapPointForCoordinate(coordinate);
	pointArr[index] = point;
	index++;*/
	
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
	
	// make sure its registered. 
	[[ShuttleDataManager sharedDataManager] registerDelegate:self];
	
	// start polling for new vehicle locations every 10 seconds. 
	_pollingTimer = [[NSTimer scheduledTimerWithTimeInterval:10
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
	
	self.route = nil;
	//self.routeInfo = nil;
	self.parentViewController = nil;
	
	self.routeLine = nil;
	self.routeLineView = nil;
	
	
    [super dealloc];
}

-(void) viewDidUnload
{
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

-(void) setRouteInfo:(ShuttleRoute *) shuttleRoute
{
	[_routeInfo release];
	_routeInfo = [shuttleRoute retain];
	
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
			NSDate* nextScheduled = [NSDate dateWithTimeIntervalSince1970:stop.nextScheduled];
			NSTimeInterval intervalTillStop = [nextScheduled timeIntervalSinceDate:[NSDate date]];
			
			if (intervalTillStop > 0) {
				NSString* subtitle = [NSString stringWithFormat:@"Arriving in %d minutes", (int)(intervalTillStop / 60)];
				[annotation setSubtitle:subtitle];
			}
		}
	}
	
	// tell the map to refresh whatever its current callout is. 
	//[_mapView refreshCallout];
}

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
	
	double latDelta = maxLat - minLat;
	double lonDelta = maxLon - minLon; 
	
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
	// make a copy since ShuttleRoute's vehicleLocations will be wiped out when it receives new data
	[self removeShuttles];
	_vehicleAnnotations = [[NSArray arrayWithArray:self.routeInfo.vehicleLocations] retain];
	[_mapView addAnnotations:_vehicleAnnotations];
}

-(void) updateUpcomingStops
{
	for(ShuttleStopMapAnnotation* annotation in _route.annotations) 
	{
		ShuttleStop* stopInfo = [_routeStops objectForKey:annotation.shuttleStop.stopID];
		
		ShuttleRoute *info = self.routeInfo;
		//if (info.upcoming != annotation.shuttleStop.upcoming) 
		if ([info.nextStopId isEqualToString:stopInfo.stopID])
		{
			annotation.shuttleStop.upcoming = YES; //info.upcoming;
			[self updateStopAnnotation:annotation];
		} 
		
		[self updateStopAnnotation:annotation];
	}
}

-(void) updateStopAnnotation:(ShuttleStopMapAnnotation*)annotation
{
	//UIImage* image = nil;
	[self.mapView addAnnotation:annotation];

	//MKAnnotationView * annotationView = [_mapView viewForAnnotation:annotation];	
	
	
    /*
	 // determine which image to use for this annotation. If our map is above 2.0, use the big one
	 if (_mapView.zoomLevel >= 2.0) {
	 image = annotation.shuttleStop.upcoming ? _largeUpcomingStopImage : _largeStopImage;
	 annotationView.layer.anchorPoint = CGPointMake(0.5, 1.0);
	 }
	 else 
	 {
	 annotationView.layer.anchorPoint = CGPointMake(0.5, 0.5);
	 image = annotation.shuttleStop.upcoming ? _smallUpcomingStopImage : _smallStopImage;
	 }
	 */
	
	
	/*UIImageView* imageView = [annotationView.subviews objectAtIndex:0];
	 imageView.image = image;
	 imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
	 annotationView.frame = imageView.frame;*/
	
	//[_mapView positionAnnotationView:annotationView];
	
}

#pragma mark User actions
-(IBAction) gpsTouched:(id)sender
{
	
	//_mapView.stayCenteredOnUserLocation = !_mapView.stayCenteredOnUserLocation;
	
	//NSString *bgImageName = [NSString stringWithFormat:@"scrim-button-background%@.png", _mapView.stayCenteredOnUserLocation ? @"-highlighted" : @""];
	//[_gpsButton setBackgroundImage:[UIImage imageNamed:bgImageName] forState:UIControlStateNormal];
	
}

-(IBAction) refreshTouched:(id)sender
{
	//_gpsButton.style = UIBarButtonItemStyleBordered;
	[_gpsButton setBackgroundImage:[UIImage imageNamed:@"scrim-button-background"] forState:UIControlStateNormal];
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
			self.routeLineView.lineWidth = 3;
		}
		
		overlayView = self.routeLineView;
		
	}
	
	return overlayView;
	
}




- (void)mapViewRegionWillChangeAnimated:(MKMapView *)mapView
{
	//[sampleView hideFromView];
	//_gpsButton.style = _mapView.stayCenteredOnUserLocation ? UIBarButtonItemStyleDone : UIBarButtonItemStyleBordered;
	//NSString *bgImageName = [NSString stringWithFormat:@"scrim-button-background%@.png", _mapView.stayCenteredOnUserLocation ? @"-highlighted" : @""];
	//[_gpsButton setBackgroundImage:[UIImage imageNamed:bgImageName] forState:UIControlStateNormal];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {

	//[sampleView setNeedsDisplay];
	//[sampleView showView];
}


- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{

	//[sampleView hideFromView];
}

- (void)mapViewRegionDidChangeAnimated:(MKMapView *)mapView
{
	//NSString *bgImageName = [NSString stringWithFormat:@"scrim-button-background%@.png", _mapView.stayCenteredOnUserLocation ? @"-highlighted" : @""];
	//[_gpsButton setBackgroundImage:[UIImage imageNamed:bgImageName] forState:UIControlStateNormal];
	//_gpsButton.style = _mapView.stayCenteredOnUserLocation ? UIBarButtonItemStyleDone : UIBarButtonItemStyleBordered;
	/*
	 CGFloat newZoomLevel = mapView.zoomLevel;
	 
	 if (newZoomLevel != _lastZoomLevel)
	 {
	 if ((newZoomLevel >= 2.0 && _lastZoomLevel < 2.0 )||
	 (newZoomLevel < 2.0 && _lastZoomLevel >= 2.0)) 
	 {
	 
	 for (ShuttleStopMapAnnotation* stop in _route.annotations) 
	 {
	 [self updateStopAnnotation:stop];
	 }
	 
	 }
	 }
	 _lastZoomLevel = mapView.zoomLevel;
     */

	//sampleView.hidden = YES;
}


-(void) locateUserFailed
{
	//if (_mapView.stayCenteredOnUserLocation) 
	//{
	//	[_gpsButton setBackgroundImage:[UIImage imageNamed:@"scrim-button-background.png"] forState:UIControlStateNormal];
	//}	
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	MKAnnotationView* annotationView = nil;
	UIImage *image;
	
	if ([annotation isKindOfClass:[ShuttleStopMapAnnotation class]]) 
	{
		annotationView = [[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"gufileg"] autorelease];
		UIImage* pin = [UIImage imageNamed:@"shuttle-stop-dot.png"];
		UIImageView* imageView = [[[UIImageView alloc] initWithImage:pin] autorelease];
		
		BOOL upComing = NO;
		if ([((ShuttleStopMapAnnotation *)annotation).shuttleStop.stopID isEqualToString:self.routeInfo.nextStopId]) {
			upComing = YES;
		}
		
		/*imageView.image = upComing ? _smallUpcomingStopImage : _smallStopImage;
		//imageView.image = ((ShuttleStopMapAnnotation *)annotation).shuttleStop.upcoming ? _smallUpcomingStopImage : _smallStopImage;
		annotationView.frame = imageView.frame;
		annotationView.canShowCallout = YES;
		
		[annotationView addSubview:imageView];
		annotationView.backgroundColor = [UIColor clearColor];*/
		
		
		UIButton *myDetailButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		myDetailButton.frame = CGRectMake(0, 0, 23, 23);
		myDetailButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		myDetailButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
		// Set the button as the callout view
		annotationView.rightCalloutAccessoryView = myDetailButton;
		
		
		annotationView.frame = imageView.frame;
		NSURL *url = [NSURL URLWithString:self.routeInfo.urlForStopMarker];
		NSData *data = [NSData dataWithContentsOfURL:url];
		UIImage *stop = [[UIImage alloc] initWithData:data];
		UIImageView* stopView = [[[UIImageView alloc] initWithImage:stop] autorelease];
		annotationView.canShowCallout = YES;
		[annotationView addSubview:stopView];
		annotationView.backgroundColor = [UIColor clearColor];
		annotationView.rightCalloutAccessoryView = myDetailButton;
		myDetailButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		myDetailButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
		
	}
	else if([annotation isKindOfClass:[ShuttleLocation class]])
	{
		ShuttleLocation* shuttleLocation = (ShuttleLocation*) annotation;
		
		annotationView = [[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"asdf"] autorelease];
		UIImage* pin = [UIImage imageNamed:@"shuttle-bus-location.png"];
		UIImageView* imageView = [[[UIImageView alloc] initWithImage:pin] autorelease];
		
		UIImage* arrow = [UIImage imageNamed:@"shuttle-bus-location-arrow.png"];
		UIImageView* arrowImageView = [[[UIImageView alloc] initWithImage:arrow] autorelease];
		
		CGAffineTransform cgCTM = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(shuttleLocation.heading));
		arrowImageView.frame = CGRectMake(9, 10, arrowImageView.frame.size.width, arrowImageView.frame.size.height);
		//CGFloat verticalAnchor = (arrowImageView.frame.size.height / 2 + 1.5) / arrowImageView.frame.size.height;
		//arrowImageView.layer.anchorPoint = CGPointMake(0.5, verticalAnchor);
		arrowImageView.transform = cgCTM;
		
		annotationView.frame = imageView.frame;
		annotationView.canShowCallout = NO;
		//[annotationView addSubview:imageView];
		//[annotationView addSubview:arrowImageView];
		
		
		NSString * pathForImage = @"http://ncsu.transloc.com/m/markers/marker.php?m=bus&c=3366FF&h=ne";
		//NSURL *url = [NSURL URLWithString:@"http://ncsu.transloc.com/m/markers/marker.php?m=bus&c=3366FF&h=ne"];
		NSString *testing = shuttleLocation.iconURL;
		NSURL *url = [NSURL URLWithString:shuttleLocation.iconURL];
		NSData *data = [NSData dataWithContentsOfURL:url];
		UIImage *marker = [[UIImage alloc] initWithData:data];
		UIImageView* markerView = [[[UIImageView alloc] initWithImage:marker] autorelease];
		[annotationView addSubview:markerView];
		
		//annotationView.backgroundColor = [UIColor clearColor];
		
		
		//annotationView.alreadyOnMap = YES;
		//annotationView.layer.anchorPoint = CGPointMake(0.5, 1.0);
	}
	
	//[sampleView setNeedsDisplay];
	return annotationView;
	
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
		
		self.routeInfo = shuttleRoute;
		
		//if (![self.mapView.routes count]) {
		//	[self.mapView addRoute:self.route];
		//	self.mapView.region = [self regionForRoute];
		//}
		
		[self addShuttles];
		[self updateUpcomingStops];
		[self.mapView setCenterCoordinate:self.mapView.region.center animated:NO];
	}
	
	
	if (hasStopInfoForMap == NO) {
		[self fallBackViewDidLoad];
		hasStopInfoForMap = YES;
	}
	
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

@end
