#import <Foundation/Foundation.h>
#import "MITModule.h"
#import "StoryDetailViewController.h"
#import "StoryXMLParser.h"

@class StoryListViewController;
@class StoryXMLParser;

@interface NewsModule : MITModule <NewsControllerDelegate, StoryXMLParserDelegate> {
	StoryListViewController *storyListChannelController;
    StoryXMLParser *xmlParser;
}

- (void)loadSearchResultsFromCache;

@property (nonatomic, retain) StoryListViewController *storyListChannelController;
@property (nonatomic, retain) StoryXMLParser *xmlParser;

@end
