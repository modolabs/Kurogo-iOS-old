#import <UIKit/UIKit.h>
#import "StoryXMLParser.h"
#import "JSONAPIRequest.h"
#import "TabScrollerBackgroundView.h"
#import "ModoSearchBar.h"

typedef int NewsCategoryId;

@class MITSearchEffects;
@class NewsStory;

@interface StoryListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,
UISearchBarDelegate, StoryXMLParserDelegate, JSONAPIDelegate, NavScrollerDelegate> {
	UITableView *storyTable;
    NSArray *stories;
    NSArray *categories;
    NewsCategoryId activeCategoryId;
	StoryXMLParser *xmlParser;
    
    NSArray *navButtons;
    
	// Nav Scroll View
	//UIScrollView *navScrollView;
	NavScrollerView *navScrollView;
	UIButton *leftScrollButton;
	UIButton *rightScrollButton;  

	// Search bits
	NSString *searchQuery;
	NSArray *searchResults;
	NSInteger totalAvailableResults;
	ModoSearchBar *theSearchBar;
	MITSearchEffects *searchOverlay;
	
	BOOL hasBookmarks;
	BOOL showingBookmarks;
	
    UIView *activityView;
    
    NSIndexPath *tempTableSelection;
    BOOL lastRequestSucceeded;
}

@property (nonatomic, retain) NSArray *stories;
@property (nonatomic, retain) NSString *searchQuery;
@property (nonatomic, retain) NSArray *searchResults;
@property (nonatomic, retain) NSArray *categories;
@property (nonatomic, assign) NewsCategoryId activeCategoryId;
@property (nonatomic, retain) StoryXMLParser *xmlParser;

- (void)pruneStories;
- (void)switchToCategory:(NewsCategoryId)category;
- (void)loadFromCache;
- (void)loadFromServer:(BOOL)loadMore;
- (void)loadSearchResultsFromCache;
- (void)loadSearchResultsFromServer:(BOOL)loadMore forQuery:(NSString *)query;
- (BOOL)canSelectPreviousStory;
- (BOOL)canSelectNextStory;
- (NewsStory *)selectPreviousStory;
- (NewsStory *)selectNextStory;
@end
