#import <Foundation/Foundation.h>

// 2 hours
#define NEWS_CATEGORY_EXPIRES_TIME 7200.0

@class NewsDataController, NewsCategory, NewsStory;

@protocol NewsDataDelegate <NSObject>

@optional

- (void)dataController:(NewsDataController *)controller didRetrieveCategories:(NSArray *)categories;
- (void)dataController:(NewsDataController *)controller didRetrieveStories:(NSArray *)stories;

- (void)dataController:(NewsDataController *)controller didMakeProgress:(CGFloat)progress;

- (void)dataController:(NewsDataController *)controller didFailWithCategoryId:(NSString *)categoryId;
- (void)dataController:(NewsDataController *)controller didReceiveSearchResults:(NSArray *)results;

- (void)dataController:(NewsDataController *)controller didPruneStoriesForCategoryId:(NSString *)categoryId;

@end

@interface NewsDataController : NSObject {
    
    NSMutableSet *_searchRequests;
    NSArray *_currentStories; // stories displayed in the view
    NSArray *_currentCategories;
}

- (BOOL)requiresKurogoServer;

@property (nonatomic, retain) NSArray *currentCategories;
@property (nonatomic, retain) NSArray *currentStories;

@property (nonatomic, retain) NewsCategory *currentCategory;
@property (nonatomic, retain) NSString *moduleTag;
@property (nonatomic, assign) id<NewsDataDelegate> delegate;

@property (nonatomic, copy) NSDate *feedListModifiedDate;

// categories
- (void)readFeedData:(NSDictionary *)feedData;
- (void)fetchCategories; // fetches from core data first, then server if no results
- (NSArray *)latestCategories;
- (void)requestCategoriesFromServer;

// regular stories
- (void)fetchStoriesForCategory:(NSString *)categoryId
                        startId:(NSString *)startId;

- (void)requestStoriesForCategory:(NSString *)categoryId
                          afterId:(NSString *)afterId; // pass nil on refresh

//- (NSArray *)latestStories;
- (BOOL)canLoadMoreStories;

// bookmarks
- (void)fetchBookmarks;

// search
- (void)searchStories:(NSString *)searchTerms;
- (void)fetchSearchResultsFromStore;
- (NSArray *)latestSearchResults;


- (void)pruneStoriesForCategoryId:(NSString *)categoryId;


- (NSArray *)searchableCategories;
- (NSArray *)bookmarkedStories;

- (NewsStory *)storyWithDictionary:(NSDictionary *)storyDict;
- (NewsCategory *)categoryWithId:(NSString *)categoryId;
- (NewsCategory *)categoryWithDictionary:(NSDictionary *)categoryDict;

@end