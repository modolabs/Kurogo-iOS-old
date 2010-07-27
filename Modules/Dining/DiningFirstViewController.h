//
//  TabSampleViewController.h
//  TabSample
//
//  Created by Muhammad Amjad on 6/22/10.
//  Copyright Modo Labs 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DiningTabViewControl.h"
#import "ConnectionWrapper.h"
#import "MenuItems.h"
#import "MIT_MobileAppDelegate.h"
#import "HoursTableViewController.h"
#import "JSONAPIRequest.h"
#import "Constants.h";
#import "DatePickerViewController.h"


@class MenuDetailsController;
@class HoursTableViewController;

@interface DiningFirstViewController : UIViewController <TabViewControlDelegate, UITableViewDelegate, UITableViewDataSource, JSONAPIDelegate, DatePickerViewControllerDelegate>
{
	IBOutlet DiningTabViewControl *_tabViewControl;
	IBOutlet UIView *_tabViewContainer;
	IBOutlet UIScrollView *_scrollView;
	IBOutlet UIView* lunchViewLink;
	IBOutlet UIView* dinnerViewLink;
	IBOutlet UIView *breakfastViewLink;
	IBOutlet UIView *_hoursView;
	IBOutlet UIView *_loadingResultView;
	IBOutlet UIView *_noResultsView;
	IBOutlet UITableView *breakfastTable;
	IBOutlet UITableView *lunchTable;
	IBOutlet UITableView *dinnerTable;
	
	IBOutlet UITableView *hoursTableView;
	HoursTableViewController *tableControl;

	UIView *datePicker;
	UIView *loadingIndicator;
	CGFloat _tabViewContainerMinHeight;
		
	NSMutableArray *_tabViews;
	
	MenuDetailsController *childController;
	NSArray *list;
	NSArray *_bkfstList;
	NSArray *_lunchList;
	NSArray *_dinnerList;
	
	NSDictionary *menuDict;
	NSDictionary *_bkfstDict;
	NSDictionary *_lunchDict;
	NSDictionary *_dinnerDict;

	NSDate *todayDate;
	
	BOOL _firstViewDone;
	int _startingTab;	
}

@property int startingTab;
@property (nonatomic, retain) NSArray *list;
@property (nonatomic, retain) NSArray *_bkfstList;
@property (nonatomic, retain) NSArray *_lunchList;
@property (nonatomic, retain) NSArray *_dinnerList;

@property (nonatomic, retain) NSDictionary *menuDict;
@property (nonatomic, retain) NSDictionary *_bkfstDict;
@property (nonatomic, retain) NSDictionary *_lunchDict;
@property (nonatomic, retain) NSDictionary *_dinnerDict;

@property (nonatomic, retain) NSDate *todayDate;
@property (nonatomic, retain) IBOutlet UITableView *hoursTableView;

-(IBAction)nextButtonPressed;
-(IBAction)previousButtonPressed;

- (void)addLoadingIndicator;
- (void)removeLoadingIndicator;

- (void) setupDatePicker;

@end

