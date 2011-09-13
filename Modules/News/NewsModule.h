#import <Foundation/Foundation.h>
#import "KGOModule.h"
#import "StoryDetailViewController.h"

@class NewsDataController;

@interface NewsModule : KGOModule /*<NewsDataDelegate>*/ {
    NSInteger totalResults;
    //id<KGOSearchResultsHolder> *searchDelegate;
    NewsDataController *_dataManager;
    NSDictionary *_payload;
}

- (NewsDataController *)dataManager;

@end
