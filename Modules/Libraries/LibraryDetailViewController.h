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
#import "LibraryDataManager.h"

@class LibraryAlias;

@interface LibraryDetailViewController : UITableViewController <MFMailComposeViewControllerDelegate, LibraryDataManagerDelegate> {
	
	UIButton * bookmarkButton;
	
	NSMutableDictionary * weeklySchedule;
	NSMutableArray * daysOfWeek;
	
	BOOL bookmarkButtonIsOn;
	
	LibraryAlias * lib;
	
	int websiteRow;
	int emailRow;
	int phoneRow;
	
	NSArray * phoneNumbersArray;
	
	UIView *footerView;
	
	NSArray * otherLibraries;
	int currentlyDisplayingLibraryAtIndex;
}

@property (nonatomic, retain) LibraryAlias * lib;
@property (nonatomic, retain) NSMutableDictionary * weeklySchedule;
@property BOOL bookmarkButtonIsOn;
@property int currentlyDisplayingLibraryAtIndex;
@property (nonatomic, retain) NSArray * otherLibraries;

- (void)setupWeeklySchedule;
-(void) setupLayout;
-(void) setDaysOfWeekArray;

-(void)emailTo:(NSString*)subject body:(NSString *)emailBody email:(NSString *)emailAddress;


@end
