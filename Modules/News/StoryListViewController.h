#import <UIKit/UIKit.h>
#import "StoryXMLParser.h"
#import "JSONAPIRequest.h"
#import "NavScrollerView.h"
#import "ModoSearchBar.h"
#import "StoryDetailViewController.h"
#import "KGOTableViewController.h"

typedef int NewsCategoryId;

@class MITSearchDisplayController;
@class NewsStory;

@interface StoryListViewController : KGOTableViewController <UISearchBarDelegate,
StoryXMLParserDelegate, JSONAPIDelegate, NavScrollerDelegate, NewsControllerDelegate> {
	UITableView *storyTable;
    NewsStory *featuredStory;
    NSArray *stories;
    NSArray *categories;
    NewsCategoryId activeCategoryId;
	StoryXMLParser *xmlParser;
    
    NSArray *navButtons;
    
	// Nav Scroll View
	NavScrollerView *navScrollView;
	UIButton *leftScrollButton;
	UIButton *rightScrollButton;  

	// Search bits
	NSString *searchQuery;
	NSArray *searchResults;
	NSInteger totalAvailableResults;
	ModoSearchBar *theSearchBar;
    MITSearchDisplayController *searchController;
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
@property (nonatomic, retain) StoryXMLParser *xmlParser;

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
