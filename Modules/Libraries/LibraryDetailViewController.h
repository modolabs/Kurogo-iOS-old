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
//#import "Library.h"
#import "LibraryDataManager.h"

// TODO: this class and ItemAvailabilityLibDetailViewController are so similar that they should just be one class.

@class LibraryAlias;

@interface LibraryDetailViewController : UITableViewController <MFMailComposeViewControllerDelegate, LibraryDataManagerDelegate> { //JSONAPIDelegate>{
	
	UIButton * bookmarkButton;
	
	NSMutableDictionary * weeklySchedule;
	NSMutableArray * daysOfWeek;
	
	BOOL bookmarkButtonIsOn;
	
	LibraryAlias * lib;
	
	int websiteRow;
	int emailRow;
	int phoneRow;
	
	NSArray * phoneNumbersArray;
	
	UILabel *footerLabel;
	
	NSArray * otherLibraries;
	int currentlyDisplayingLibraryAtIndex;
	
	JSONAPIRequest * apiRequest;
	
	UIView * headerView;
    
    BOOL isItemAvailabilityView; // true if this VC is for an item's available library, false for generic detail view
    
	// from ItemAvailabilityLibDetailViewController
	NSString * displayName;

}

@property (nonatomic, retain) LibraryAlias * lib;
@property (nonatomic, retain) NSMutableDictionary * weeklySchedule;
@property BOOL bookmarkButtonIsOn;

// from LibraryDetailViewController
@property int currentlyDisplayingLibraryAtIndex;
@property (nonatomic, retain) NSArray * otherLibraries;

- (void)setupWeeklySchedule;
-(void) setupLayout;
-(void) setDaysOfWeekArray;

-(void)emailTo:(NSString*)subject body:(NSString *)emailBody email:(NSString *)emailAddress;

/*
// from ItemAvailabilityLibDetailViewController
-(id) initWithStyle:(UITableViewStyle)style 
		displayName: (NSString *) dispName
		 currentInd:(int) index
			library:(Library *)library
 otherLibDictionary:(NSDictionary *) otherLibDictionary;
*/

@end
