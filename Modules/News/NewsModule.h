#import <Foundation/Foundation.h>
#import "KGOModule.h"
#import "StoryDetailViewController.h"
#import "NewsDataManager.h"

@class NewsDataManager;

@interface NewsModule : KGOModule <NewsDataDelegate> {
    NSInteger totalResults;
    //id<KGOSearchResultsHolder> *searchDelegate;
    NewsDataManager *_dataManager;
}

- (NewsDataManager *)dataManager;

@end
