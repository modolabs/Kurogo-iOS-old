//
//  LibrariesMainViewController.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/15/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "JSONAPIRequest.h"

@class ModoSearchBar;
@class MITSearchDisplayController;

@interface LibrariesMainViewController : UIViewController <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource> {

	MITSearchDisplayController *searchController;
	ModoSearchBar *theSearchBar;
	
	NSString *searchTerms;
	
	UITableView *_tableView;
	
	// a custom button since we are not using the default bookmark button
	UIButton* _bookmarkButton;
	
	NSArray * mainViewTableOptions1;
	NSArray * mainViewTableOptions2;
			  
	NSArray * bookmarkedLibraries;
	NSArray * bookmarkedItems;
	
	BOOL hasBookmarkedLibraries;
	BOOL hasBookmarkedItems;
}

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) MITSearchDisplayController *searchController;
@property (nonatomic, retain) NSString *searchTerms;
@property (nonatomic, retain) ModoSearchBar *searchBar;

-(void) setUpLayOut;
-(void) hideToolBar;

@end
