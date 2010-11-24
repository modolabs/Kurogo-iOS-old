//
//  LibraryDetailViewController.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/19/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LibraryWeeklyScheduleViewController.h"
#import <MessageUI/MFMailComposeViewController.h>;


@interface LibraryDetailViewController : UITableViewController <MFMailComposeViewControllerDelegate>{
	
	UIButton * bookmarkButton;
	
	NSDictionary * weeklySchedule;
	NSArray * daysOfWeek;
	
	BOOL bookmarkButtonIsOn;

}

@property (nonatomic, retain) NSDictionary * weeklySchedule;
@property BOOL bookmarkButtonIsOn;

-(void)emailTo:(NSString*)subject body:(NSString *)emailBody email:(NSString *)emailAddress;

@end
