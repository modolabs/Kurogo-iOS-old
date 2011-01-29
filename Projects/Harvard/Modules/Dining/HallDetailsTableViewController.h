/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

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
