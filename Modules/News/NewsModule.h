#import <Foundation/Foundation.h>
#import "KGOModule.h"
#import "StoryDetailViewController.h"

@class StoryListViewController;

@interface NewsModule : KGOModule <NewsControllerDelegate> {
	StoryListViewController *storyListChannelController;
    NSInteger totalResults;
}

- (void)loadSearchResultsFromCache;

@property (nonatomic, retain) StoryListViewController *storyListChannelController;

@end
