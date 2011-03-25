#import <Foundation/Foundation.h>
#import "KGORequestManager.h"
#import "NewsCategory.h"
#import "NewsStory.h"
#import "NewsImage.h"

typedef NSString* NewsCategoryId;

@protocol NewsDataDelegate <NSObject>

@optional
- (void)categoriesUpdated:(NSArray *)categories;

- (void)storiesUpdated:(NSArray *)stories forCategory:(NewsCategory *)category;

- (void)storiesDidMakeProgress:(CGFloat)progress forCategoryId:(NewsCategoryId)categoryId;

- (void)storiesDidFailWithCategoryId:(NewsCategoryId)categoryId;

- (void)searchResults:(NSArray *)results forSearchTerms:(NSString *)searchTerms;

@end

@interface NewsDataManager : NSObject<KGORequestDelegate> {
    NSMutableSet *delegates;
    KGORequest *storiesRequest;
    NSMutableSet *searchRequests;
}

+ (NewsDataManager *)sharedManager;

- (void)requestCategories;

- (void)requestStoriesForCategory:(NewsCategoryId)categoryID loadMore:(BOOL)loadMore forceRefresh:(BOOL)forceRefresh;

- (void) search:(NSString *)searchTerms;

- (void)registerDelegate:(id<NewsDataDelegate>)delegate;

- (void)unregisterDelegate:(id<NewsDataDelegate>)delegate;

- (NSInteger)loadMoreStoriesQuantityForCategoryId:(NewsCategoryId)categoryID;

- (BOOL)busy;

- (void)saveImageData:(NSData *)data url:(NSString *)url;

- (void)story:(NewsStory *)story bookmarked:(BOOL)bookmarked;

- (NSArray *)bookmarkedStories;

@property (nonatomic, retain) KGORequest *storiesRequest;
@property (nonatomic, retain) NSMutableSet *searchRequests;
@property (assign) BOOL firstSearchResultReceived;

@end
