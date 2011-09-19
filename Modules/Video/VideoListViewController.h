#import <Foundation/Foundation.h>
#import "KGOTableViewController.h"
#import "VideoDataManager.h"
#import "KGOScrollingTabstrip.h"
#import "KGOSearchBar.h"
#import "KGOSearchDisplayController.h"
#import "Video.h"

@interface VideoListViewController : UITableViewController <
KGOScrollingTabstripSearchDelegate> {

    BOOL showingBookmarks;
}

@property (nonatomic, retain) VideoDataManager *dataManager;
@property (nonatomic, retain) KGOScrollingTabstrip *navScrollView;
@property (nonatomic, retain) NSArray *videos;
// Array of NSDictionaries containing title and value keys.
@property (nonatomic, retain) NSArray *videoSections;
@property (assign) NSInteger activeSectionIndex;

@property (nonatomic, retain) KGOSearchBar *theSearchBar;

@end
