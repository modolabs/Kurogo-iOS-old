#import <Foundation/Foundation.h>
#import "KGORequestManager.h"
#import "NewsCategory.h"
#import "NewsStory.h"
#import "NewsImage.h"

@protocol NewsDataDelegate <NSObject>

@optional
- (void)categoriesUpdated:(NSArray *)categories;

- (void)storiesUpdated:(NSArray *)stories forCategory:(NewsCategory *)category;

- (void)storiesDidMakeProgress:(CGFloat)progress forCategoryId:(NSString *)categoryId;

- (void)storiesDidFailWithCategoryId:(NSString *)categoryId;

- (void)searchResults:(NSArray *)results forSearchTerms:(NSString *)searchTerms;

@end

@interface NewsDataManager : NSObject<KGORequestDelegate> {
    NSMutableSet *delegates;
    KGORequest *storiesRequest;
    NSMutableSet *searchRequests;
}

+ (NewsDataManager *)sharedManager;

- (void)requestCategories;

- (void)requestStoriesForCategory:(NSString *)categoryID loadMore:(BOOL)loadMore forceRefresh:(BOOL)forceRefresh;

- (void) search:(NSString *)searchTerms;

- (NSArray *)searchableCategories;

- (void)registerDelegate:(id<NewsDataDelegate>)delegate;

- (void)unregisterDelegate:(id<NewsDataDelegate>)delegate;

- (NSInteger)loadMoreStoriesQuantityForCategoryId:(NSString *)categoryID;

- (BOOL)busy;

- (void)saveImageData:(NSData *)data url:(NSString *)url;

- (void)story:(NewsStory *)story bookmarked:(BOOL)bookmarked;

- (NSArray *)bookmarkedStories;

@property (nonatomic, retain) KGORequest *storiesRequest;
@property (nonatomic, retain) NSMutableSet *searchRequests;

@end
