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
#import "JSONAPIRequest.h"
#import "Library.h"


@interface LibraryDetailViewController : UITableViewController <MFMailComposeViewControllerDelegate, JSONAPIDelegate>{
	
	UIButton * bookmarkButton;
	
	NSMutableDictionary * weeklySchedule;
	NSArray * daysOfWeek;
	
	BOOL bookmarkButtonIsOn;
	
	Library * lib;
	
	int websiteRow;
	int emailRow;
	int phoneRow;
	
	NSArray * phoneNumbersArray;
	
	UILabel *footerLabel;
	
	NSArray * otherLibraries;
	int currentlyDisplayingLibraryAtIndex;
	
	JSONAPIRequest * apiRequest;
	
	UIView * headerView;

}

@property int currentlyDisplayingLibraryAtIndex;
@property (nonatomic, retain) NSArray * otherLibraries;
@property (nonatomic, retain) Library * lib;
@property (nonatomic, retain) NSMutableDictionary * weeklySchedule;
@property BOOL bookmarkButtonIsOn;


-(void) setupLayout;

-(void)emailTo:(NSString*)subject body:(NSString *)emailBody email:(NSString *)emailAddress;

@end
