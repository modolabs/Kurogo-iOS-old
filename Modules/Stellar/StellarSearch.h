
#import <Foundation/Foundation.h>
#import "StellarModel.h"


@class StellarMainTableController;

@interface StellarSearch : NSObject <
	UITableViewDataSource, 
	UITableViewDelegate, 
	ClassesSearchDelegate> {

		BOOL activeMode;
		BOOL hasSearchInitiated;
		NSArray *lastResults;
		StellarMainTableController *viewController;
		
		NSInteger actualCount;
}

@property (nonatomic, retain) NSArray *lastResults;
@property (nonatomic, readonly) BOOL activeMode;

- (id) initWithViewController: (StellarMainTableController *)controller;

//- (void) searchOverlayTapped;

- (BOOL) isSearchResultsVisible;

@end
