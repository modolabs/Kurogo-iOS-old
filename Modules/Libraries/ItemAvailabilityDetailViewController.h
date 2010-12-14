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
	/*
	 availabilityCategories = array containing dictionaries
							{type=>[string], callNumber => [string], available=>[number], checkedOut=>[number], unavailable=>[number]}
	 */
	
	UIView * headerView;
	
	NSArray * arrayWithAllLibraries;
	/*
	 arrayWithAllLibraries = array containing [Dictionary]:
	 {library:[Library*] availabilityCategories:[Array*]}
	 */
	int currentIndex;
	
	NSString * openToday;
	
	JSONAPIRequest * apiRequest;
	
	JSONAPIRequest * parentViewApiRequest;	
	
	NSMutableDictionary * sectionType; // this will determine which of the three types of section layouts to use
	
	UIButton * infoButton;
	
	int showingSection; // for use in the ActionSheet
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
-(UITableViewCell *) sectionTypeZero:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
-(UITableViewCell *) sectionTypeOne:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;

-(void) showActionSheet:(int)sectionIndex;

@end
