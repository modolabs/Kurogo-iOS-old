
#import <Foundation/Foundation.h>
#import "StellarModel.h"


@class StellarMainTableController;

@interface StellarMainSearch : NSObject <
UITableViewDataSource, 
UITableViewDelegate, 
ClassesSearchDelegate> {
	
	BOOL activeMode;
	BOOL hasSearchInitiated;
	NSArray *lastResults;
	StellarMainTableController *viewController;
	UITableView *resultsTableView;
	NSMutableDictionary *groups;
	NSMutableDictionary *schoolNameToShortNames;
	NSInteger actualCount;
}

@property (nonatomic, retain) NSArray *lastResults;
@property (nonatomic, readonly) BOOL activeMode;
@property (nonatomic, retain) NSMutableDictionary *groups;

- (id) initWithViewController: (StellarMainTableController *)controller;

//- (void) searchOverlayTapped;

- (BOOL) isSearchResultsVisible;

-(NSMutableDictionary *) uniqueCourseGroups;
-(NSMutableDictionary *) uniqueCourseGroupsForCountDisplayOnly: (id)object;

@end
