#import "NewsDataController.h"
#import "ConnectionWrapper.h"
#import "NewsCategory.h"
#import "NewsStory.h"
#import "NewsImage.h"

@interface RSSNewsDataController : NewsDataController <ConnectionWrapperDelegate, NSXMLParserDelegate> {

    ConnectionWrapper *_storiesConnection;
    NSXMLParser *_xmlParser;
    NSThread *_parserThread;

    NSMutableArray *_currentStack;
    NSMutableDictionary *_channelData;
    NSMutableDictionary *_currentItemData;
    
    NSArray *_feeds;
    
    BOOL _shouldAbort;
    BOOL _done;
}

//- (void)pruneStories;

@property (nonatomic, assign) id<NewsDataDelegate> delegate;
@property (nonatomic, retain) NSXMLParser *xmlParser;
@property (nonatomic, retain) ConnectionWrapper *storiesConnection;

@property (nonatomic, retain) NSArray *feeds;

@end
