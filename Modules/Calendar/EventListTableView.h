#import <UIKit/UIKit.h>
#import "CalendarEventsViewController.h"
#import "CalendarConstants.h"

@interface EventListTableView : UITableView <UITableViewDelegate, UITableViewDataSource> {

	NSArray *events;
	BOOL isSearchResults;
	CalendarEventsViewController *parentViewController;
	NSIndexPath *previousSelectedIndexPath;
    NSString *searchSpan; // make it 7 days by default
	
}

@property (nonatomic, retain) NSArray *events;
@property (nonatomic, assign) BOOL isSearchResults;
@property (nonatomic, assign) CalendarEventsViewController *parentViewController;
@property (nonatomic, retain) NSString *searchSpan;

@end
