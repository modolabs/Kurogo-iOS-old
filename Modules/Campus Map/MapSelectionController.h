#import <Foundation/Foundation.h>
#import "JSONAPIRequest.h"

@class CampusMapViewController;
@class MITLoadingActivityView;

typedef enum {
	MapSelectionControllerSegmentBookmarks = 0,
	MapSelectionControllerSegmentRecents,
	MapSelectionControllerSegmentBrowse,
} MapSelectionControllerSegment;

@interface MapSelectionController : UIViewController <UITableViewDelegate, UITableViewDataSource, JSONAPIDelegate> {
    
	CampusMapViewController *_mapVC;
	NSArray *_toolbarButtonItems;

    UITableView *_tableView;
    NSArray *_categoryItems;
    NSArray *_tableItems;
    MITLoadingActivityView *_loadingView;

	UIBarButtonItem *_cancelButton;
    MapSelectionControllerSegment _selectedSegment;
}

- (void)switchToSegment:(MapSelectionControllerSegment)segment;

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) NSArray *tableItems;
@property (nonatomic, assign) CampusMapViewController *mapVC;
@property (nonatomic, readonly) NSArray *toolbarButtonItems;
@property (nonatomic, readonly) UIBarButtonItem *cancelButton;

@end
