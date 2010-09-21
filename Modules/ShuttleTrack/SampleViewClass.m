//
//  SampleViewClass.m
//  Harvard Mobile
//
//  Created by Muhammad Amjad on 9/8/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import "SampleViewClass.h"


@implementation SampleViewClass

@synthesize mapView = _mapView;
@synthesize points = _points;
@synthesize lineColor = _lineColor;


-(id) initWithRoute:(NSMutableArray*)routePoints mapView:(MKMapView*)givenMapView
{
	self.mapView = givenMapView;
	self = [super initWithFrame:CGRectMake(0, 50, givenMapView.frame.size.width, givenMapView.frame.size.height)];
	[self setBackgroundColor:[UIColor clearColor]];
	
	[self setMapView:self.mapView];
	[self setPoints:routePoints];
	
	
	// determine the extents of the trip points that were passed in, and zoom in to that area.
	CLLocationDegrees maxLat = -90;
	CLLocationDegrees maxLon = -180;
	CLLocationDegrees minLat = 90;
	CLLocationDegrees minLon = 180;
	
	for(int idx = 0; idx < self.points.count; idx++)
	{
		CLLocation* currentLocation = [self.points objectAtIndex:idx];
		if(currentLocation.coordinate.latitude > maxLat)
			maxLat = currentLocation.coordinate.latitude;
		if(currentLocation.coordinate.latitude < minLat)
			minLat = currentLocation.coordinate.latitude;
		if(currentLocation.coordinate.longitude > maxLon)
			maxLon = currentLocation.coordinate.longitude;
		if(currentLocation.coordinate.longitude < minLon)
			minLon = currentLocation.coordinate.longitude;
	}
	
	MKCoordinateRegion region;
	region.center.latitude = (maxLat + minLat) / 2;
	region.center.longitude = (maxLon + minLon) / 2;
	region.span.latitudeDelta = maxLat - minLat;
	region.span.longitudeDelta = maxLon - minLon;
	
	//[self.mapView setRegion:region];
	//[self.mapView setDelegate:self];
	//[self.mapView addSubview:self];
	
	return self;
}

- (void)drawRect:(CGRect)rect
{
	// only draw our lines if we're not int he moddie of a transition and we
	// acutally have some points to draw.
	if(!self.hidden && nil != self.points && self.points.count > 0)
	{
		CGContextRef context = UIGraphicsGetCurrentContext();
		
		if(nil == self.lineColor)
			self.lineColor = [UIColor redColor];
		
		CGContextSetStrokeColorWithColor(context, self.lineColor.CGColor);
		CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 1.0);
		
		// Draw them with a 2.0 stroke width so they are a bit more visible.
		CGContextSetLineWidth(context, 4.0);
		
		for(int idx = 0; idx < self.points.count; idx++)
		{
			CLLocation* location = [self.points objectAtIndex:idx];
			CGPoint point = [_mapView convertCoordinate:location.coordinate toPointToView:self];
			
			if(idx == 0)
			{
				// move to the first point
				CGContextMoveToPoint(context, point.x, point.y);
			}
			else
			{
				CGContextAddLineToPoint(context, point.x, point.y);
			}
		}
		
		CGContextStrokePath(context);
	}
	//self.hidden = NO;
}

-(void)hideFromView {
	self.hidden = YES;
}

-(void)showView {
	self.hidden = NO;
}
#pragma mark mapView delegate functions
- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
	// turn off the view of the route as the map is chaning regions. This prevents
	// the line from being displayed at an incorrect positoin on the map during the
	// transition.
	self.hidden = YES;
}
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
	// re-enable and re-poosition the route display.
	self.hidden = NO;
	[self setNeedsDisplay];
}

-(void) dealloc
{
	[_points release];
	[_mapView release];
	[super dealloc];
}

@end
