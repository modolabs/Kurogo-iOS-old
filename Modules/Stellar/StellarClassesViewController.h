#import <Foundation/Foundation.h>
#import "StellarModel.h"
#import "MITModuleURL.h"
#import "StellarSearch.h"

@class StellarClassesViewController;
@interface LoadClassesInTable : NSObject<ClassesLoadedDelegate> {
	StellarClassesViewController *tableController;
}

@property (nonatomic, assign) StellarClassesViewController *tableController;
@end

@class MITSearchDisplayController;

@interface StellarClassesViewController : UIViewController<UISearchBarDelegate, UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource> {
	StellarCourse *course;
	NSArray *classes;
	LoadClassesInTable *currentClassLoader;
	UIView *loadingView;
	
	MITModuleURL *url;
	
	StellarSearch *stellarSearch;
	MITSearchDisplayController *searchController;
	NSString *doSearchTerms;
	BOOL doSearchExecute;
    BOOL hasSearchInitiated;
	BOOL isViewAppeared;
	
	UITableView *harvardClassesTableView;
}

@property (nonatomic, retain) NSArray *classes;
@property (nonatomic, retain) LoadClassesInTable *currentClassLoader;
@property (nonatomic, retain) UIView *loadingView;

@property (retain) MITSearchDisplayController *searchController;
@property (nonatomic, retain) NSString *doSearchTerms;

@property (nonatomic, retain) UITableView *harvardClassesTableView;

@property (readonly) MITModuleURL *url;

- (id) initWithCourse: (StellarCourse *)course;

- (void) doSearch:(NSString *)searchTerms execute:(BOOL)execute;
- (void) showSearchResultsTable;
- (void) hideSearchResultsTable;
- (void) reloadData;
- (void)presentSearchResults:(NSArray *)searchResults query:(NSString *)query;

@end
