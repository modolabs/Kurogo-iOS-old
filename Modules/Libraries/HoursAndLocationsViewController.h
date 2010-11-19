//
//  HoursAndLocationsViewController.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/18/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NavScrollerView.h"
#import "LibraryLocationsMapViewController.h"

@class LibraryLocationsMapViewController;

@interface HoursAndLocationsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	
	UIBarButtonItem * _viewTypeButton;
	UIView * listOrMapView;
	UITableView * _tableView;
	
	UISegmentedControl *segmentedControl;
	UISegmentedControl * filterButtonControl;
	UISegmentedControl * gpsButtonControl;
	
	NSMutableArray * allLibraries;
	
	BOOL showingMapView;
	BOOL gpsPressed;
	
	LibraryLocationsMapViewController * librayLocationsMapView;
}

@property (nonatomic, retain) UIView * listOrMapView;
@property BOOL showingMapView;
@property (nonatomic, retain) LibraryLocationsMapViewController * librayLocationsMapView;

-(void)displayTypeChanged:(id)sender;
-(void) filterButtonPressed:(id)sender;
-(void) gpsButtonPressed:(id)sender;
-(void) setMapViewMode:(BOOL)showMap animated:(BOOL)animated; 

@end
