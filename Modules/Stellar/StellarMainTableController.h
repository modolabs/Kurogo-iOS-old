#import <Foundation/Foundation.h>
#import	"StellarCourseGroup.h"
#import "StellarModel.h"
#import "StellarSearch.h"
#import "MITSearchEffects.h"
#import "MITModuleURL.h"


@interface StellarMainTableController : UITableViewController <CoursesLoadedDelegate, ClearMyStellarDelegate> {
	NSArray *courseGroups;
	NSArray *myStellar;
	BOOL myStellarUIisUpToDate;
	StellarSearch *stellarSearch;
	UISearchDisplayController *searchController;
	MITSearchEffects *translucentOverlay;
	UIView *loadingView;
	MITModuleURL *url;
	BOOL isViewAppeared;		
	NSString *doSearchTerms;
	BOOL doSearchExecute;
}

@property (retain) NSArray *courseGroups;
@property (retain) NSArray *myStellar;
@property (retain) UISearchDisplayController *searchController;
@property (retain) UIControl *translucentOverlay;
@property (retain) UIView *loadingView;
@property (readonly) BOOL myStellarUIisUpToDate;
@property (readonly) MITModuleURL *url;

- (void) reloadMyStellarData;
- (void) reloadMyStellarUI;
- (void) reloadMyStellarNotifications;

- (void) doSearch:(NSString *)searchTerms execute:(BOOL)execute;
- (void) showSearchResultsTable;
- (void) showTranslucentOverlayWithDelay:(BOOL)useDelay;
- (void) showLoadingView;
- (void) hideSearchResultsTable;
- (void) hideTranslucentOverlay;
- (void) hideLoadingView;

@end
