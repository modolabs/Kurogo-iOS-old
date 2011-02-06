#import <UIKit/UIKit.h>
#import "CalendarEventsViewController.h"
#import "CalendarConstants.h"
#import "KGOTableViewController.h"

@interface EventListTableView : UITableView <UITableViewDelegate, KGOTableViewDataSource> {

	NSArray *events;
	BOOL isSearchResults;
	CalendarEventsViewController *parentViewController;
	NSIndexPath *previousSelectedIndexPath;
    NSString *searchSpan; // make it 7 days by default
	BOOL isAcademic;
	
}

@property (nonatomic, retain) NSArray *events;
@property (nonatomic, assign) BOOL isSearchResults;
@property (nonatomic, assign) CalendarEventsViewController *parentViewController;
@property (nonatomic, retain) NSString *searchSpan;
@property (nonatomic, assign) BOOL isAcademic;

@end
