/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import <UIKit/UIKit.h>
#import "JSONAPIRequest.h"
#import "HallDetailsTableViewController.h"
#import "MIT_MobileAppDelegate.h";
#import "DiningFirstViewController.h"
#import "DiningHallStatus.h"
//#import "MultiLineTableViewCell.h"
#import "DiningMultiLineCell.h"

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
