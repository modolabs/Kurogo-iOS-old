//
//  LibrariesSearchViewController.h
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/23/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LibrariesMainViewController.h"
#import "JSONAPIRequest.h"
#import "ModoSearchBar.h"
#import "MITSearchDisplayController.h"

@class LibrariesMainViewController;
@class ModoSearchBar;
@class MITSearchDisplayController;

@interface LibrariesSearchViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, JSONAPIDelegate> {
	
	BOOL activeMode;
	BOOL hasSearchInitiated;
	NSMutableDictionary *lastResults;
	
	LibrariesMainViewController * viewController;
	
	NSInteger actualCount;
	
	UITableView *_tableView;
	
	MITSearchDisplayController *searchController;
	ModoSearchBar *theSearchBar;
	
	NSArray *searchResults;
	NSString *searchTerms;
	NSString *previousSearchTerm;
	
	UIView *loadingView;
	
	BOOL requestWasDispatched;
	JSONAPIRequest *api;

}

@property (nonatomic, retain) UIView *loadingView;
@property (nonatomic, retain) MITSearchDisplayController *searchController;
@property (nonatomic, retain) NSArray *searchResults;
@property (nonatomic, retain) NSString *searchTerms;
@property (nonatomic, retain) ModoSearchBar *searchBar;
@property (nonatomic, retain) NSMutableDictionary *lastResults;
@property (nonatomic, readonly) BOOL activeMode;

- (id) initWithViewController: (LibrariesMainViewController *)controller;

//- (void) searchOverlayTapped;

- (BOOL) isSearchResultsVisible;

-(void) hideToolBar;

- (void)performSearch;
- (void)presentSearchResults:(NSArray *)theSearchResults;
- (void)showLoadingView;
- (void)cleanUpConnection;

- (void)handleWarningMessage:(NSString *)message title:(NSString *)theTitle;

@end