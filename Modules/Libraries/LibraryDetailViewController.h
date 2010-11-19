//
//  LibraryDetailViewController.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/19/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LibraryDetailViewController : UITableViewController {
	
	UIButton * bookmarkButton;
	
	NSDictionary * weeklySchedule;
	NSArray * daysOfWeek;

}

@property (nonatomic, retain) NSDictionary * weeklySchedule;

@end
