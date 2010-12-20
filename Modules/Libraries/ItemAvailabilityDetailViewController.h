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


#define sectionType0 @"type0"
#define sectionType1 @"type1"
#define sectionType2 @"type2"

@interface ItemAvailabilityDetailViewController : UITableViewController <JSONAPIDelegate, UIActionSheetDelegate>{

	NSString * libraryName;
	NSString * libraryId;
	NSString * primaryName;
	NSString * type;
	
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
}

@property (nonatomic, retain) JSONAPIRequest *parentViewApiRequest;

- (id)initWithStyle:(UITableViewStyle)style 
			libName:(NSString *)libName
		   primName:(NSString *)primName
			  libId:(NSString *) libId
			libType: (NSString *) libType
			   item:(LibraryItem *)libraryItem 
		 categories:(NSArray *)availCategories
allLibrariesWithItem: (NSArray *) allLibraries
			 index :(int) index;

-(void) setupLayout;

-(UITableViewCell *) sectionTypeONE:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
-(UITableViewCell *) sectionTypeTWO:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
-(UITableViewCell *) sectionTypeTHREE:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
-(UITableViewCell *) sectionTypeFOUR:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;

- (CGFloat)heightForRowAtIndexPathSectionONE:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
- (CGFloat)heightForRowAtIndexPathSectionTWO:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
- (CGFloat)heightForRowAtIndexPathSectionTHREE:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
- (CGFloat)heightForRowAtIndexPathSectionFOUR:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;

-(void) showActionSheet:(NSArray *)items;

@end
