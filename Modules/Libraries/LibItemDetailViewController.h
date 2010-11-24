//
//  LibItemDetailViewController.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/24/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LibItemDetailCell.h"


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
	
}

@property BOOL bookmarkButtonIsOn;

-(id) initWithStyle:(UITableViewStyle)style 
			  title:(NSString *)title 
			 author: (NSString *) authorName 
	   otherDetail1:(NSString *) otherDetail1 
	   otherDetail2:(NSString *) otherDetail2 
	   otherDetail3: (NSString *) otherDetail3 
		  libraries:(NSDictionary *)libraries;

@end
