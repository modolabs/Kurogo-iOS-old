//
//  BookmarkedHoursAndLocationsViewController.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/29/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NavScrollerView.h"
#import "LibraryLocationsMapViewController.h"
#import "LibraryDetailViewController.h"
#import "JSONAPIRequest.h"

@interface BookmarkedHoursAndLocationsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, JSONAPIDelegate> {
	
	UIBarButtonItem * _viewTypeButton;
	UIView * listOrMapView;
	UITableView * _tableView;
	
	UISegmentedControl *segmentedControl;
	UISegmentedControl * filterButtonControl;
	UISegmentedControl * gpsButtonControl;
	
	NSMutableArray * allLibraries;
	NSMutableArray * allOpenLibraries;
	NSMutableArray * allArchives;
	
	BOOL showingMapView;
	BOOL gpsPressed;
	BOOL showingOnlyOpen;
	
	LibraryLocationsMapViewController * librayLocationsMapView;
	
	BOOL showArchives;
	
}

@property BOOL showArchives;
@property (nonatomic, retain) UIView * listOrMapView;
@property BOOL showingMapView;
@property (nonatomic, retain) LibraryLocationsMapViewController * librayLocationsMapView;

-(void)displayTypeChanged:(id)sender;
-(void) gpsButtonPressed:(id)sender;
-(void) setMapViewMode:(BOOL)showMap animated:(BOOL)animated; 

@end
