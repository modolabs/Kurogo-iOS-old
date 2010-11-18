//
//  HoursAndLocationsViewController.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/18/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NavScrollerView.h"


@interface HoursAndLocationsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	
	UIBarButtonItem * _viewTypeButton;
	UIView * listOrMapView;
	UITableView * _tableView;
	
	UISegmentedControl *segmentedControl;
	UISegmentedControl * filterButtonControl;
	UISegmentedControl * gpsButtonControl;
	
	NSMutableArray * allLibraries;
	
	BOOL showingMapView;

}

@property (nonatomic, retain) UIView * listOrMapView;
@property BOOL showingMapView;

-(void)displayTypeChanged;
-(void) filterButtonPressed;
-(void) gpsButtonPressed;

@end
