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

- (void)didReceiveSearchResults:(NSArray *)results forSearchTerms:(NSString *)searchTerms;

@end

@interface NewsDataManager : NSObject<KGORequestDelegate> {
    NSMutableSet *delegates;
    KGORequest *storiesRequest;
    NSMutableSet *searchRequests;
}

- (void)requestCategories;

- (void)requestStoriesForCategory:(NSString *)categoryID loadMore:(BOOL)loadMore forceRefresh:(BOOL)forceRefresh;

- (void) search:(NSString *)searchTerms;

- (NSArray *)searchableCategories;

- (NSInteger)loadMoreStoriesQuantityForCategoryId:(NSString *)categoryID;

- (BOOL)busy;

- (void)saveImageData:(NSData *)data url:(NSString *)url;

- (void)story:(NewsStory *)story bookmarked:(BOOL)bookmarked;

- (NSArray *)bookmarkedStories;

@property (nonatomic, assign) id<NewsDataDelegate> delegate;

@property (nonatomic, retain) KGORequest *storiesRequest;
@property (nonatomic, retain) NSMutableSet *searchRequests;

@property (nonatomic, retain) NSString *moduleTag;

@end
