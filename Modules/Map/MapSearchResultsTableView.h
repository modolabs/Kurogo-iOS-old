#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"

@class CampusMapViewController;

@interface MapSearchResultsTableView : UITableView <UITableViewDelegate, KGOTableViewDataSource> {

	NSArray *_searchResults;
	CampusMapViewController* _campusMapVC; // this is our parent VC
	BOOL _isCategory;

}

@property (nonatomic, retain) NSArray* searchResults;
@property (nonatomic, assign) CampusMapViewController* campusMapVC;

@property BOOL isCategory;

@end
