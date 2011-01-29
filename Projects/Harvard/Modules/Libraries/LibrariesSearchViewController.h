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
#import "Constants.h"

@class LibrariesMainViewController;
@class ModoSearchBar;
@class MITSearchDisplayController;

@interface LibrariesSearchViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, JSONAPIDelegate> {
	
	BOOL activeMode;
	BOOL hasSearchInitiated;
	NSMutableDictionary *lastResults;
	
	LibrariesMainViewController * viewController;
	
	NSInteger actualCount; // total results
    NSInteger startIndex;
    NSInteger endIndex;
    NSInteger pageSize;
    NSMutableDictionary *searchParams;
	
	UITableView *_tableView;
	
	MITSearchDisplayController *searchController;
	ModoSearchBar *theSearchBar;
	
	NSString *searchTerms;
    NSInteger formatIndex;
    NSInteger locationIndex;
    NSInteger pubdateIndex;
	//NSString *previousSearchTerm;
    
    NSString *keywordText;
    NSString *titleText;
    NSString *authorText;
	BOOL englishOnlySwitch;
	
	BOOL requestWasDispatched;
	
	// a custom button to link to Advanced Search
	UIButton* _advancedSearchButton;
    
}

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) MITSearchDisplayController *searchController;
@property (nonatomic, retain) NSString *searchTerms;
@property (nonatomic, readwrite) NSInteger formatIndex;
@property (nonatomic, readwrite) NSInteger locationIndex;
@property (nonatomic, readwrite) NSInteger pubdateIndex;
@property (nonatomic, retain) NSString *keywordText;
@property (nonatomic, retain) NSString *titleText;
@property (nonatomic, retain) NSString *authorText;
@property (nonatomic, readwrite) BOOL englishOnlySwitch;
@property (nonatomic, retain) ModoSearchBar *searchBar;
@property (nonatomic, retain) NSMutableDictionary *lastResults;
@property (nonatomic, readonly) BOOL activeMode;
@property (nonatomic, retain) NSMutableDictionary *searchParams;

- (id) initWithViewController: (LibrariesMainViewController *)controller;

//- (void) searchOverlayTapped;

- (BOOL) isSearchResultsVisible;

-(void) hideToolBar;

//- (void)presentSearchResults:(NSArray *)theSearchResults;
- (void)cleanUpConnection;

- (void)handleWarningMessage:(NSString *)message title:(NSString *)theTitle;

@end