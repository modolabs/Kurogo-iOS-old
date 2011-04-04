#import <Foundation/Foundation.h>
#import "KGOModule.h"
#import "StoryDetailViewController.h"
#import "NewsDataManager.h"

@class StoryListViewController;

@interface NewsModule : KGOModule <NewsDataDelegate> {
	StoryListViewController *storyListChannelController;
    NSInteger totalResults;
    id<KGOSearchResultsHolder> *searchDelegate;
}

- (void)loadSearchResultsFromCache;

@property (nonatomic, retain) StoryListViewController *storyListChannelController;
@property (nonatomic, retain) id<KGOSearchResultsHolder> searchDelegate;

@end
