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
#import "LibraryDataManager.h"

@interface ItemAvailabilityDetailViewController : UITableViewController <LibraryDataManagerDelegate, UIActionSheetDelegate> {

	LibraryItem * libItem;
	
	NSArray * availabilityCategories;
	
	NSArray * arrayWithAllLibraries;

	int currentIndex;
	
	NSString * openToday;
	
	NSMutableDictionary * sectionType; // this will determine which of the three types of section layouts to use
	
	NSArray * actionSheetItems; // for use in the ActionSheet
	
	BOOL limitedView;
    
    NSString *requestedLibID;
    
    LibraryItem *libraryItem;
    LibraryAlias *libraryAlias;
    
    NSArray *tableCells;
    BOOL collectionOnly;
    BOOL uniformHoldingStatus;
}

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
