//
//  LibItemDetailViewController.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/24/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LibraryItem.h"
//#import "JSONAPIRequest.h"
#import <MapKit/MapKit.h>
#import "UnderlinedUILabel.h"
#import "LibraryDataManager.h"

@interface LibItemDetailViewController : UITableViewController <CLLocationManagerDelegate, LibraryItemDetailDelegate, LibraryDetailDelegate> {

	NSArray * locationsWithItem;
	
	BOOL bookmarkButtonIsOn;
	
	LibraryItem * libItem;
	NSDictionary * libItemDictionary;
	
	int currentIndex;
	
	UIView * loadingIndicator;
	
    NSMutableArray *displayLibraries;
	
	CLLocation * currentLocation;
	
	CLLocationManager * locationManager;
	
	BOOL displayImage;
    BOOL canShowMap;
    
	UIView * thumbnail;
    CGFloat headerTextHeight;
}

@property BOOL bookmarkButtonIsOn;
@property BOOL displayImage;

-(id) initWithStyle:(UITableViewStyle)style 
		libraryItem:(LibraryItem *) libraryItem
		  itemArray: (NSDictionary *) results
	currentItemIdex: (int) itemIndex
	   imageDisplay:(BOOL) imageDisplay;


-(void) setupLayout;

- (void)addLoadingIndicator:(UIView *)view;
- (void)removeLoadingIndicator;

// function and constants for getting meters in units of user's locale.
// TODO: put these somewhere in Common
#define METERS_PER_FOOT 0.3048
#define FEET_PER_MILE 5280
- (NSString *)textForDistance:(CLLocationDistance)meters;

@end
