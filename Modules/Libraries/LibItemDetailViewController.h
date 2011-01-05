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

@interface LibItemDetailViewController : UITableViewController </*JSONAPIDelegate, */CLLocationManagerDelegate, LibraryItemDetailDelegate> {
	
	//NSString * itemTitle;
	//NSString * author;
	//NSString * otherDetailLine1;
	//NSString * otherDetailLine2;
	//NSString * otherDetailLine3;
	
	//NSDictionary *librariesWithItem;
	
	NSArray * locationsWithItem;
	
	BOOL bookmarkButtonIsOn;
	
	UIButton *bookmarkButton;
	UIButton *mapButton;
	
	LibraryItem * libItem;
	NSDictionary * libItemDictionary;
	
	int currentIndex;
	
	JSONAPIRequest * apiRequest;
	
	UIView * loadingIndicator;
	
	//NSMutableDictionary * displayNameAndLibraries;
    NSMutableArray *displayLibraries;
	
	CLLocation * currentLocation;
	
	CLLocationManager * locationManager;
	
	BOOL displayImage;
	UIView * thumbnail;
	
	NSString * fullImageLink;
}

@property BOOL bookmarkButtonIsOn;
@property BOOL displayImage;

-(id) initWithStyle:(UITableViewStyle)style 
		libraryItem:(LibraryItem *) libraryItem
		  itemArray: (NSDictionary *) results
	currentItemIdex: (int) itemIndex
	   imageDisplay:(BOOL) imageDisplay;


-(void) setupLayout;
//-(void)setUpdetails: (LibraryItem *) libraryItem;

- (void)addLoadingIndicator:(UIView *)view;
- (void)removeLoadingIndicator;

// function and constants for getting meters in units of user's locale.
// TODO: put these somewhere in Common
#define METERS_PER_FOOT 0.3048
#define FEET_PER_MILE 5280
- (NSString *)textForDistance:(CLLocationDistance)meters;

@end
