#import <Foundation/Foundation.h>
#import "KGORequestManager.h"
#import "NewsCategory.h"
#import "NewsStory.h"
#import "NewsImage.h"

typedef NSString* NewsCategoryId;

@protocol NewsDataDelegate <NSObject>

@optional
- (void) categoriesUpdated:(NSArray *)categories;

- (void) storiesUpdated:(NSArray *)stories forCategory:(NewsCategory *)category;

- (void) storiesDidMakeProgress:(CGFloat)progress forCategoryId:(NewsCategoryId)categoryId;

@end

@interface NewsDataManager : NSObject<KGORequestDelegate> {
    NSMutableSet *delegates;
    KGORequest *storiesRequest;
}

+ (NewsDataManager *)sharedManager;

- (void)requestCategories;

- (void)requestStoriesForCategory:(NewsCategoryId)categoryID loadMore:(BOOL)loadMore forceRefresh:(BOOL)forceRefresh;

- (void)registerDelegate:(id<NewsDataDelegate>)delegate;

- (void)unregisterDelegate:(id<NewsDataDelegate>)delegate;

- (NSInteger)loadMoreStoriesQuantityForCategoryId:(NewsCategoryId)categoryID;

- (BOOL)busy;

- (void)saveImageData:(NSData *)data url:(NSString *)url;

- (void)story:(NewsStory *)story bookmarked:(BOOL)bookmarked;

- (NSArray *)bookmarkedStories;

@property (nonatomic, retain) KGORequest *storiesRequest;

@end
