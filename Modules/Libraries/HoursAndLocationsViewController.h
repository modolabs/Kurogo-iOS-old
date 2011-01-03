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
#import "LibraryDetailViewController.h"
//#import "JSONAPIRequest.h"
#import "LibraryDataManager.h"

@class LibraryLocationsMapViewController;

@interface HoursAndLocationsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, LibraryDataManagerDelegate> { //JSONAPIDelegate> {
	
	UIBarButtonItem * _viewTypeButton;
	UITableView * _tableView;
	
	UISegmentedControl *segmentedControl;
	UISegmentedControl * filterButtonControl;
	UISegmentedControl * gpsButtonControl;

	BOOL showingMapView;
	BOOL gpsPressed;
	BOOL showingOnlyOpen;
	
    // TODO: implement this as just a mapView instead of an entire UIViewController
	LibraryLocationsMapViewController * librayLocationsMapView;
	
	BOOL showArchives;
    BOOL showBookmarks;
	
	JSONAPIRequest * apiRequest;
	
	NSString * typeOfRepo;
	NSArray *_currentLibraries;
}

@property BOOL showArchives;
//@property (nonatomic, retain) UIView * listOrMapView;
@property BOOL showingMapView;
@property (nonatomic, retain) LibraryLocationsMapViewController * librayLocationsMapView;
@property (nonatomic) BOOL showBookmarks;
@property (nonatomic, retain) NSString *typeOfRepo;

-(void)displayTypeChanged:(id)sender;
-(void) gpsButtonPressed:(id)sender;
-(void) setMapViewMode:(BOOL)showMap animated:(BOOL)animated; 

@end
