#import <Foundation/Foundation.h>
#import "KGOModule.h"
#import "StoryDetailViewController.h"
#import "NewsDataController.h"

@class NewsDataController;

typedef enum {
    NewsDataControllerClassJSON = 1,
    NewsDataControllerClassRSS = 2
} NewsDataControllerClass;

@interface NewsModule : KGOModule <NewsDataDelegate> {
    NSInteger totalResults;
    //id<KGOSearchResultsHolder> *searchDelegate;
    NewsDataController *_dataManager;
    NewsDataControllerClass _controllerClass;
    NSDictionary *_payload;
}

- (NewsDataController *)dataManager;

@end
