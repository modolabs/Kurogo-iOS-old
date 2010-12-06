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


@interface ItemAvailabilityDetailViewController : UITableViewController <JSONAPIDelegate>{

	Library * library;
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
	
}

- (id)initWithStyle:(UITableViewStyle)style 
			library:(Library *)lib 
			   item:(LibraryItem *)libraryItem 
		 categories:(NSArray *)availCategories
allLibrariesWithItem: (NSArray *) allLibraries
			 index :(int) index;

-(void) setupLayout;

@end
