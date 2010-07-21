//
//  HoursTableViewController.h
//  MIT Mobile
//
//  Created by Muhammad Amjad on 7/19/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSONAPIRequest.h"
#import "HallDetailsTableViewController.h"
#import "MIT_MobileAppDelegate.h";
#import "DiningFirstViewController.h"

@class HallDetailsTableViewController;
@class DiningFirstViewController;

@interface HoursTableViewController : UITableViewController <JSONAPIDelegate>{

	NSArray *hallProperties;
	HallDetailsTableViewController *childHallViewController;
	DiningFirstViewController *parentViewController;
}


@property (nonatomic, retain) NSArray *hallProperties;
@property (nonatomic, retain) DiningFirstViewController *parentViewController;

@end
