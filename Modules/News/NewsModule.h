#import <Foundation/Foundation.h>
#import "KGOModule.h"
#import "StoryDetailViewController.h"
#import "StoryXMLParser.h"

@class StoryListViewController;
@class StoryXMLParser;

@interface NewsModule : KGOModule <NewsControllerDelegate, StoryXMLParserDelegate> {
	StoryListViewController *storyListChannelController;
    StoryXMLParser *xmlParser;
    NSInteger totalResults;
}

- (void)loadSearchResultsFromCache;

@property (nonatomic, retain) StoryListViewController *storyListChannelController;
@property (nonatomic, retain) StoryXMLParser *xmlParser;

@end
