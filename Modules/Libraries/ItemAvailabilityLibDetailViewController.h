
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

@interface ItemAvailabilityLibDetailViewController : UITableViewController <MFMailComposeViewControllerDelegate, LibraryDataManagerDelegate> { //JSONAPIDelegate>{
	
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
	
	NSDictionary * otherLibraries;
	int currentlyDisplayingLibraryAtIndex;
	
	NSString * displayName;
	
	JSONAPIRequest * apiRequest;
	
	UIView * headerView;
	
}

@property (nonatomic, retain) Library * lib;
@property (nonatomic, retain) NSMutableDictionary * weeklySchedule;
@property BOOL bookmarkButtonIsOn;


-(id) initWithStyle:(UITableViewStyle)style 
		displayName: (NSString *) dispName
		 currentInd:(int) index
			library:(Library *)library
	  otherLibDictionary:(NSDictionary *) otherLibDictionary;

- (void)setupWeeklySchedule;
-(void) setupLayout;
-(void) setDaysOfWeekArray;

-(void)emailTo:(NSString*)subject body:(NSString *)emailBody email:(NSString *)emailAddress;

@end