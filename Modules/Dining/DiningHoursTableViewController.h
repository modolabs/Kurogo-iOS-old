//
//  DiningHoursTableViewViewController.h
//  MIT Mobile
//
//  Created by Muhammad Amjad on 7/19/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HarvardDiningAPI.h"
#import "ConnectionWrapper.h"
#import "MIT_MobileAppDelegate.h"


@interface DiningHoursTableViewViewController : UITableViewController <JSONLoadedDelegate> {

	NSArray *diningHalls;
	NSDictionary *diningHallDetails;
}

@property (nonatomic, retain) NSArray *diningHalls;
@property (nonatomic, retain) NSDictionary *diningHallDetails;

@end
