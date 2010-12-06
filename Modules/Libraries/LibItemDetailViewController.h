//
//  LibItemDetailViewController.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/24/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LibItemDetailCell.h"
#import "LibraryItem.h"
#import "JSONAPIRequest.h"


@interface LibItemDetailViewController : UITableViewController {
	
	NSString * itemTitle;
	NSString * author;
	NSString * otherDetailLine1;
	NSString * otherDetailLine2;
	NSString * otherDetailLine3;
	
	NSDictionary *librariesWithItem;
	
	BOOL bookmarkButtonIsOn;
	
	UIButton *bookmarkButton;
	UIButton *mapButton;
	
	LibraryItem * libItem;
	NSDictionary * libItemDictionary;
	
	int currentIndex;
	
	JSONAPIRequest * apiRequest;
}

@property BOOL bookmarkButtonIsOn;

-(id) initWithStyle:(UITableViewStyle)style 
		  libraries:(NSDictionary *)libraries
		libraryItem:(LibraryItem *) libraryItem
		  itemArray: (NSDictionary *) results
	currentItemIdex: (int) itemIndex;	


-(void) setupLayout;
-(void)setUpdetails: (LibraryItem *) libraryItem;
@end
