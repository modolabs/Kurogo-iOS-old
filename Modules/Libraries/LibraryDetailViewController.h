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
#import "LibraryDataManager.h"

// TODO: this class and ItemAvailabilityLibDetailViewController are so similar that they should just be one class.

@interface LibraryDetailViewController : UITableViewController <MFMailComposeViewControllerDelegate, LibraryDataManagerDelegate> { //JSONAPIDelegate>{
	
	UIButton * bookmarkButton;
	
	NSMutableDictionary * weeklySchedule;
	NSMutableArray * daysOfWeek;
	
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

- (void)setupWeeklySchedule;
-(void) setupLayout;
-(void) setDaysOfWeekArray;

-(void)emailTo:(NSString*)subject body:(NSString *)emailBody email:(NSString *)emailAddress;

@end
