//
//  StellarCoursesViewController.h
//  MIT Mobile
//
//  Created by Muhammad Amjad on 8/11/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "StellarCourseGroup.h"
#import "MITModuleURL.h"
#import "StellarSearch.h"
#import "StellarModel.h"


@class MITSearchDisplayController;

@interface StellarCoursesViewController : UIViewController<UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource> {
	
	StellarCourseGroup *courseGroup;
	MITModuleURL *url;
	
	StellarSearch *stellarSearch;
	MITSearchDisplayController *searchController;
	NSString *doSearchTerms;
	BOOL doSearchExecute;
	UIView *loadingView;
    BOOL hasSearchInitiated;
	BOOL isViewAppeared;
	
	UITableView *coursesTableView;
	

}


@property (retain) StellarCourseGroup *courseGroup;
@property (readonly) MITModuleURL *url;
@property (retain) MITSearchDisplayController *searchController;
@property (nonatomic, retain) NSString *doSearchTerms;
@property (retain) UIView *loadingView;

- (id) initWithCourseGroup: (StellarCourseGroup *)courseGroup;


- (void) doSearch:(NSString *)searchTerms execute:(BOOL)execute;
- (void) showSearchResultsTable;
- (void) showLoadingView;
- (void) hideSearchResultsTable;
- (void) hideLoadingView;
- (void) reloadData;
- (void)presentSearchResults:(NSArray *)searchResults query:(NSString *)query;
@end
