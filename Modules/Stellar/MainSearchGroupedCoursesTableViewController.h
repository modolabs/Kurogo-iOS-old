#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "StellarModel.h"
#import "MITModuleURL.h"
#import "StellarSearch.h"


@class MITSearchDisplayController;

@interface MainSearchGroupedCoursesTableViewController : UIViewController 
<UISearchBarDelegate, UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource, ClassesSearchDelegate> {
	StellarCourse *course;
	NSString *stellarCourseGroupString;
	NSArray *classes;
	//LoadClassesInTable *currentClassLoader;
	UIView *loadingView;
	
	MITModuleURL *url;
	
	StellarSearch *stellarSearch;
	MITSearchDisplayController *searchController;
	NSString *doSearchTerms;
	BOOL doSearchExecute;
    BOOL hasSearchInitiated;
	BOOL isViewAppeared;
	
	UITableView *mainSearchClassesTableView;
	MainSearchGroupedCoursesTableViewController *viewController;
	NSString *searchTerm;
	
	NSInteger actualCount;
}

@property (nonatomic, retain) NSArray *classes;
@property (nonatomic, retain) UIView *loadingView;

@property (retain) MITSearchDisplayController *searchController;
@property (nonatomic, retain) NSString *doSearchTerms;

@property (nonatomic, retain) UITableView *mainSearchClassesTableView;

@property (readonly) MITModuleURL *url;

- (id) initWithCourse: (StellarCourse *)course;

- (void) doSearch:(NSString *)searchTerms execute:(BOOL)execute;
- (void) showSearchResultsTable;
- (void) hideSearchResultsTable;
- (void) reloadData;
- (void)presentSearchResults:(NSArray *)searchResults query:(NSString *)query;

- (MainSearchGroupedCoursesTableViewController *) initWithViewController: (UIViewController *)controller;
-(void)setSearchString: (NSString *)searchTerms;
-(void)setCourseGroupString: (NSString *)courseGroupString;

@end
