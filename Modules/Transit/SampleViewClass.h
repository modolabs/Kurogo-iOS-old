//
//  SampleViewClass.h
//  Harvard Mobile
//
//  Created by Muhammad Amjad on 9/8/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "ShuttleRoute.h"
#import "ShuttleDataManager.h"


@interface SampleViewClass : UIView {
	MKMapView* _mapView;
	NSMutableArray* _points;
	UIColor* _lineColor;
}

-(id) initWithRoute:(NSArray*)routePoints mapView:(MKMapView*)mapView;
-(void)hideFromView;
-(void)showView;

@property (nonatomic, retain) NSMutableArray* points;
@property (nonatomic, retain) MKMapView* mapView;
@property (nonatomic, retain) UIColor* lineColor;

@end
