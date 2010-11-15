//
//  LibrariesMainViewController.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/15/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONAPIRequest.h"

@class ModoSearchBar;
@class MITSearchDisplayController;

@interface LibrariesMainViewController : UIViewController <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, JSONAPIDelegate>{

	MITSearchDisplayController *searchController;
	ModoSearchBar *theSearchBar;
	
	NSArray *searchResults;
	NSString *searchTerms;
	
	UITableView *_tableView;
	
	UIView *loadingView;
	BOOL requestWasDispatched;
	JSONAPIRequest *api;
	
	// a custom button since we are not using the default bookmark button
	UIButton* _bookmarkButton;
	
	NSArray * mainViewTableOptions;
}

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) MITSearchDisplayController *searchController;
@property (nonatomic, retain) NSArray *searchResults;
@property (nonatomic, retain) NSString *searchTerms;
@property (nonatomic, retain) ModoSearchBar *searchBar;
@property (nonatomic, retain) UIView *loadingView;

- (void)performSearch;
- (void)presentSearchResults:(NSArray *)theSearchResults;
- (void)showLoadingView;
- (void)cleanUpConnection;

@end
