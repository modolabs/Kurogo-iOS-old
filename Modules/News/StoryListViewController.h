#import <UIKit/UIKit.h>
#import "JSONAPIRequest.h"
#import "NewsDataManager.h"
#import "KGOScrollingTabstrip.h"
#import "KGOSearchBar.h"
#import "StoryDetailViewController.h"
#import "KGOTableViewController.h"

@class KGOSearchDisplayController;
@class NewsStory;

@interface StoryListViewController : KGOTableViewController <KGOSearchBarDelegate, NewsDataDelegate, KGOScrollingTabstripDelegate, NewsControllerDelegate> {
	UITableView *storyTable;
    NewsStory *featuredStory;
    NSArray *stories;
    NSArray *categories;
    NewsCategoryId activeCategoryId;
    BOOL activeCategoryHasMoreStories;
    
    NSArray *navButtons;
    
	// Nav Scroll View
	KGOScrollingTabstrip *navScrollView;
	UIButton *leftScrollButton;
	UIButton *rightScrollButton;  

	// Search bits
	NSString *searchQuery;
	NSArray *searchResults;
	NSInteger totalAvailableResults;
	KGOSearchBar *theSearchBar;
    KGOSearchDisplayController *searchController;
    NSInteger searchIndex;
	
	BOOL hasBookmarks;
	BOOL showingBookmarks;
	
    UIView *activityView;
    
    NSIndexPath *tempTableSelection;
    BOOL lastRequestSucceeded;
}

@property (nonatomic, assign) NSInteger totalAvailableResults;
@property (nonatomic, retain) NewsStory *featuredStory;
@property (nonatomic, retain) NSArray *stories;
@property (nonatomic, retain) NSString *searchQuery;
@property (nonatomic, retain) NSArray *searchResults;
@property (nonatomic, retain) NSArray *categories;
@property (nonatomic, assign) NewsCategoryId activeCategoryId;

- (void)presentSearchResults:(NSArray *)results searchText:(NSString *)searchText;
- (void)showSearchBar;

- (void)pruneStories;
- (void)switchToCategory:(NewsCategoryId)category;
- (void)loadFromCache;
- (void)loadFromServer:(BOOL)loadMore;
- (void)loadSearchResultsFromCache;
- (void)loadSearchResultsFromServer:(BOOL)loadMore forQuery:(NSString *)query;
- (void)refreshCategories;

//- (BOOL)canSelectPreviousStory;
//- (BOOL)canSelectNextStory;
//- (NewsStory *)selectPreviousStory;
//- (NewsStory *)selectNextStory;
@end
