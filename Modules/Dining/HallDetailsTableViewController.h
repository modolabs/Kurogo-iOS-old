//
//  HallDetailsTableViewController.h
//  MIT Mobile
//
//  Created by Muhammad Amjad on 7/20/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MultiLineTableViewCell.h"
#import "DiningHallStatus.h"

@class DiningHallStatus;

@interface HallDetailsTableViewController : UIViewController<UITableViewDelegate, UITableViewDataSource> {

	NSDictionary *itemDetails;
	DiningHallStatus *hallStatus;
	
	UITableView *detailsTableView;
	NSInteger currentStat;

}

@property (nonatomic, retain) NSDictionary *itemDetails;

-(void)setDetails:(NSDictionary *)details;
-(void)setStatus:(DiningHallStatus *)statusDetails;

@end
