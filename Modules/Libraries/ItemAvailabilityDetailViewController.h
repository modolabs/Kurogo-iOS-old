//
//  ItemAvailabilityDetailViewController.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 12/6/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Library.h"
#import "LibraryItem.h"
#import "JSONAPIRequest.h"
#import "LibraryDataManager.h"

#define sectionType0 @"type0"
#define sectionType1 @"type1"
#define sectionType2 @"type2"

@interface ItemAvailabilityDetailViewController : UITableViewController </*JSONAPIDelegate,*/ LibraryDataManagerDelegate, UIActionSheetDelegate>{

	//NSString * libraryName;
	//NSString * libraryId;
	//NSString * primaryName;
	//NSString * type;
	
	LibraryItem * libItem;
	
	NSArray * availabilityCategories;
	
	UIView * headerView;
	
	NSArray * arrayWithAllLibraries;

	int currentIndex;
	
	NSString * openToday;
	
	JSONAPIRequest * apiRequest;
	
	JSONAPIRequest * parentViewApiRequest;	
	
	NSMutableDictionary * sectionType; // this will determine which of the three types of section layouts to use
	
	UIButton * infoButton;
	
	NSArray * actionSheetItems; // for use in the ActionSheet
	
	BOOL limitedView;
    
    NSString *requestedLibID;
    
    LibraryItem *libraryItem;
    LibraryAlias *libraryAlias;
    
    NSArray *tableCells;
}

@property (nonatomic, retain) JSONAPIRequest *parentViewApiRequest;

@property (nonatomic, retain) NSString *openToday;

@property (nonatomic, retain) LibraryItem *libraryItem;
@property (nonatomic, retain) LibraryAlias *libraryAlias;
@property (nonatomic, retain) NSArray *availabilityCategories;
@property (nonatomic, retain) NSArray *arrayWithAllLibraries;
@property (nonatomic) NSInteger currentIndex;

@property (nonatomic, retain) NSArray *tableCells;

- (void)libraryDetailsDidLoad:(NSNotification *)aNotification;
- (void)setupLayout;
- (void)showActionSheet;
- (void)showModalViewForRequest:(NSString *)title url:(NSString *)urlString;
- (void)processAvailabilityData;

@end
