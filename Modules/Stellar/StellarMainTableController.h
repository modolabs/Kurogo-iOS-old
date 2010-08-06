#import <Foundation/Foundation.h>
#import	"StellarCourseGroup.h"
#import "StellarModel.h"
#import "StellarSearch.h"
#import "MITModuleURL.h"

@class MITSearchDisplayController;

@interface StellarMainTableController : UIViewController <UISearchBarDelegate,
UITableViewDelegate, UITableViewDataSource, CoursesLoadedDelegate, ClearMyStellarDelegate> {
    UITableView *_tableView;
	NSArray *courseGroups;
	NSArray *myStellar;
	BOOL myStellarUIisUpToDate;
	StellarSearch *stellarSearch;
    MITSearchDisplayController *searchController;
	UIView *loadingView;
	MITModuleURL *url;
	BOOL isViewAppeared;		
	NSString *doSearchTerms;
	BOOL doSearchExecute;
    BOOL hasSearchInitiated;
}

@property (nonatomic, retain) UITableView *tableView;
@property (retain) NSArray *courseGroups;
@property (retain) NSArray *myStellar;
@property (retain) MITSearchDisplayController *searchController;
@property (retain) UIView *loadingView;
@property (readonly) BOOL myStellarUIisUpToDate;
@property (readonly) MITModuleURL *url;

- (void) reloadMyStellarData;
- (void) reloadMyStellarUI;
- (void) reloadMyStellarNotifications;

- (void) doSearch:(NSString *)searchTerms execute:(BOOL)execute;
- (void) showSearchResultsTable;
//- (void) showTranslucentOverlayWithDelay:(BOOL)useDelay;
- (void) showLoadingView;
- (void) hideSearchResultsTable;
//- (void) hideTranslucentOverlay;
- (void) hideLoadingView;
- (void) reloadData;

@end
