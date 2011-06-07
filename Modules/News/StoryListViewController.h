#import <UIKit/UIKit.h>
#import "NewsDataController.h"
#import "KGOScrollingTabstrip.h"
#import "KGOSearchBar.h"
#import "KGOSearchDisplayController.h"
#import "StoryDetailViewController.h"
#import "KGOTableViewController.h"
#import "MITThumbnailView.h"

@class KGOSearchDisplayController;
@class NewsStoryTableViewCell;
@class NewsStory;

@interface StoryListViewController : KGOTableViewController <KGOSearchBarDelegate,
NewsDataDelegate, KGOScrollingTabstripDelegate, KGOSearchDisplayDelegate> {
    
	IBOutlet UITableView *_storyTable;
    IBOutlet NewsStoryTableViewCell *_storyCell;
    
	// Nav Scroll View
	IBOutlet KGOScrollingTabstrip *_navScrollView;
	
    // progress bar
    IBOutlet UIView *_activityView;
    IBOutlet UILabel *_loadingLabel;
    IBOutlet UILabel *_lastUpdateLabel;
    IBOutlet UIProgressView *_progressView;
    
    NewsStory *featuredStory;
    NSString *activeCategoryId;
    
	// Search bits
	NSInteger totalAvailableResults;
	KGOSearchBar *theSearchBar;
    KGOSearchDisplayController *searchController;
    NSInteger searchIndex;
	
	BOOL showingBookmarks;
}

@property (nonatomic, retain) NewsStory *featuredStory;
@property (nonatomic, retain) NSArray *stories;
@property (nonatomic, retain) NSArray *categories;
@property (nonatomic, retain) NSString *activeCategoryId;
@property (nonatomic, retain) NewsDataController *dataManager;

- (void)showSearchBar;
- (void)switchToCategory:(NSString *)category;
- (void)switchToBookmarks;

@end
