#import "RSSNewsDataController.h"
#import "CoreDataManager.h"
#import "Foundation+KGOAdditions.h"


@implementation RSSNewsDataController

@synthesize storiesConnection = _storiesConnection;
@synthesize xmlParser = _xmlParser;
@synthesize delegate;
@synthesize feeds = _feeds;

// NSUserDefaults

//NSString * const StoriesLastUpdateKey = @"storiesLastUpdate";
//static NSInteger kStoriesTimeoutInterval = 7200; // 2 hours

// RSS <channel> tags

NSString * const RSSTagChannel        = @"channel";
NSString * const RSSTagChannelTitle   = @"title";
NSString * const RSSTagChannelSummary = @"description";
NSString * const RSSTagChannelLink    = @"link";
NSString * const RSSTagChannelPubDate = @"pubDate";

// RSS <item> tags

NSString * const RSSTagItem           = @"item";
NSString * const RSSTagItemGUID       = @"guid";
NSString * const RSSTagItemTitle      = @"title";
NSString * const RSSTagItemLink       = @"link";
NSString * const RSSTagItemSummary    = @"description";
NSString * const RSSTagItemPubDate    = @"pubDate";
NSString * const RSSTagItemEnclosure  = @"enclosure";
NSString * const RSSTagItemBody       = @"content:encoded";

#pragma mark NewsDataController

- (void)requestCategoriesFromServer
{
    NSMutableArray *categories = [NSMutableArray array];
    
    if (self.feeds) {
        for (NSDictionary *feedDict in self.feeds) {
            NewsCategory *category = [self categoryWithDictionary:feedDict];
            if (category) {
                [categories addObject:category];
            }
        }
    }
    _currentCategories = [categories retain];
    [[CoreDataManager sharedManager] saveData];
    
    if ([self.delegate respondsToSelector:@selector(dataController:didRetrieveCategories:)]) {
        [self.delegate dataController:self didRetrieveCategories:_currentCategories];
    }
}

- (NewsCategory *)categoryWithDictionary:(NSDictionary *)categoryDict
{
    NewsCategory *category = nil;
    NSString *categoryId = [categoryDict stringForKey:@"id" nilIfEmpty:YES];
    NSString *url = [categoryDict stringForKey:@"url" nilIfEmpty:YES];
    if (!categoryId && url) {
        categoryId = url;
    }
    if (categoryId) {
        category = [self categoryWithId:categoryId];
        if (!category) {
            category = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:NewsCategoryEntityName];
            category.moduleTag = self.moduleTag;
            category.category_id = categoryId;
        }
        category.title = [categoryDict stringForKey:@"title" nilIfEmpty:YES];
        category.url = url;
        category.isMainCategory = [NSNumber numberWithBool:YES];
    }
    return category;
}

- (void)searchStories:(NSString *)searchTerms
{
    
}

- (NewsStory *)storyWithDictionary:(NSDictionary *)storyDict {
    NSString *title = [[storyDict dictionaryForKey:RSSTagItemTitle] stringForKey:@"value" nilIfEmpty:YES];
    NSString *link = [[storyDict dictionaryForKey:RSSTagItemLink] stringForKey:@"value" nilIfEmpty:YES];
    NSString *summary = [[storyDict dictionaryForKey:RSSTagItemSummary] stringForKey:@"value" nilIfEmpty:YES];
    NSDate *pubDate = [[storyDict dictionaryForKey:RSSTagItemPubDate] dateForKey:@"value" format:@"EEE, d MMM yyyy HH:mm:ss ZZZZZ"];
    NSString *enclosure = [[[storyDict dictionaryForKey:RSSTagItemEnclosure] dictionaryForKey:@"attributes"] stringForKey:@"url" nilIfEmpty:YES];
    NSString *body = [[storyDict dictionaryForKey:RSSTagItemBody] stringForKey:@"value" nilIfEmpty:YES];
    
    NSString *GUID = [[storyDict dictionaryForKey:RSSTagItemGUID] stringForKey:@"value" nilIfEmpty:YES];
    if (!GUID) {
        // create a hash out of everything else
        GUID = [NSString stringWithFormat:@"%d%d%d", [title hash], [link hash], [pubDate hash]];
    }
    
    // use existing story if it's already in the db
    NewsStory *story = [[CoreDataManager sharedManager] uniqueObjectForEntity:NewsStoryEntityName 
                                                                    attribute:@"identifier" 
                                                                        value:GUID];
    // otherwise create new
    if (!story) {
        story = (NewsStory *)[[CoreDataManager sharedManager] insertNewObjectForEntityForName:NewsStoryEntityName];
        story.identifier = GUID;
    }
    
    story.postDate = pubDate;
    story.title = title;
    story.link = link;
    story.summary = summary;
    if (body) {
        story.body = body;
        story.hasBody = [NSNumber numberWithBool:YES];
    }
    
    if (enclosure) {
        if (!story.thumbImage) {
            story.thumbImage = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:NewsImageEntityName];
        }
        story.thumbImage.url = enclosure;
        story.thumbImage.thumbParent = story;
    } else {
        story.thumbImage = nil;
    }
    
    return story;
}

- (void)requestStoriesForCategory:(NSString *)categoryId afterId:(NSString *)afterId
{
    if (![categoryId isEqualToString:self.currentCategory.category_id]) {
        self.currentCategory = [self categoryWithId:categoryId];
    }
    
    if (_parserThread) {
        if (![_parserThread isFinished]) {
            DLog(@"%s called twice on the same instance", __PRETTY_FUNCTION__);
            return;
        }
        [_parserThread release];
    }
    
    NSURL *url = [NSURL URLWithString:self.currentCategory.url];
    if (url) {
        _parserThread = [[NSThread alloc] initWithTarget:self selector:@selector(downloadAndParse:) object:url];
        [_parserThread start];
    } else {
        // do something about broken category
    }
}

- (void)readFeedData:(NSDictionary *)feedData
{
    NSArray *feeds = [feedData arrayForKey:@"feeds"];
    if (feeds) {
        self.feeds = feeds;
        
    } else {
        NSString *url = [feedData stringForKey:@"url" nilIfEmpty:YES];
        if (url) {
            NSDictionary *feed = [NSDictionary dictionaryWithObject:url forKey:@"url"];
            self.feeds = [NSArray arrayWithObject:feed];
        }
    }
}

#pragma mark download and parse thread

- (void)abort {
    _shouldAbort = YES;
	[_parserThread cancel];
}

- (void)downloadAndParse:(NSURL *)url {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	_done = NO;
    
    self.storiesConnection = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
    BOOL requestStarted = [_storiesConnection requestDataFromURL:url];
	if (requestStarted) {

        [self performSelectorOnMainThread:@selector(reportProgress:)
                               withObject:[NSNumber numberWithFloat:0]
                            waitUntilDone:NO];
        
		do {
			if ([[NSThread currentThread] isCancelled]) {
				if (self.storiesConnection) {
					[self.storiesConnection cancel];
					self.storiesConnection = nil;
				}
				if (self.xmlParser) {
					[self.xmlParser abortParsing];
					self.xmlParser = nil;
				}
				break;
			}
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        } while (!_done);
        
	} else {
        [self performSelectorOnMainThread:@selector(parseError:) withObject:nil waitUntilDone:NO];
    }
    
    [pool drain];
}

#pragma mark -

#pragma mark ConnectionWrapperDelegate

- (void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data
{
	if (_shouldAbort) {
		return;
	}
    self.storiesConnection = nil;
    
    [self performSelectorOnMainThread:@selector(reportProgress:)
                           withObject:[NSNumber numberWithFloat:0.3]
                        waitUntilDone:NO];
    
    self.xmlParser = [[[NSXMLParser alloc] initWithData:data] autorelease];
	self.xmlParser.delegate = self;
    _currentStack = [[NSMutableArray alloc] init];
	[self.xmlParser parse];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self performSelectorOnMainThread:@selector(parseError:)
                           withObject:nil
                        waitUntilDone:NO];
}

- (void)connection:(ConnectionWrapper *)wrapper madeProgress:(CGFloat)progress
{
    [self performSelectorOnMainThread:@selector(reportProgress:)
                           withObject:[NSNumber numberWithFloat:progress]
                        waitUntilDone:NO];
}

#pragma mark NSXMLParser delegation

- (NSArray *)channelTags
{
    static NSArray *channelTags = nil;
    if (!channelTags) {
        channelTags = [[NSArray alloc] initWithObjects:RSSTagChannelTitle, RSSTagChannelLink, RSSTagChannelPubDate, RSSTagChannelSummary, nil];
    }
    return channelTags;
}

- (NSArray *)itemTags
{
    static NSArray *itemTags = nil;
    if (!itemTags) {
        itemTags = [[NSArray alloc] initWithObjects:
                    RSSTagItemTitle, RSSTagItemLink, RSSTagItemPubDate, RSSTagItemBody,
                    RSSTagItemSummary, RSSTagItemEnclosure, RSSTagItemGUID, nil];
    }
    return itemTags;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:RSSTagChannel]) {
        [_channelData release];
        _channelData = [[NSMutableDictionary alloc] init];
        for (NSString *tag in [self channelTags]) {
            [_channelData setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSMutableString string], @"value", nil]
                             forKey:tag];
        }
             
    } else if ([elementName isEqualToString:RSSTagItem]) {
        [_currentItemData release];
        _currentItemData = [[NSMutableDictionary alloc] init];
        for (NSString *tag in [self itemTags]) {
            NSLog(@"jytdjtyj %@ %@", tag, attributeDict);
            [_currentItemData setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSMutableString string], @"value", nil]
                                 forKey:tag];
        }
        
    } else if (_currentItemData) {
        if (attributeDict.count) {
            NSMutableDictionary *dict = [_currentItemData objectForKey:elementName];
            [dict setObject:attributeDict forKey:@"attributes"];
        }
    }
    
    [_currentStack addObject:elementName];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (_shouldAbort) {
        [parser abortParsing];
        return;
    }
    
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSString *currentElement = [_currentStack lastObject];
    if (!currentElement) {
        DLog(@"_currentStack is empty");
        return;
    }
    
    NSMutableString *currentValue = nil;
    
    if (_currentItemData) { // we are inside an item
        currentValue = [[_currentItemData objectForKey:currentElement] objectForKey:@"value"];
    } else if (_channelData) { // we are inside the channel
        currentValue = [[_channelData objectForKey:currentElement] objectForKey:@"value"];
    }
    
    if (currentValue) {
        [currentValue appendString:string];
    }
}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
{
    NSAutoreleasePool *tinyPool = [[NSAutoreleasePool alloc] init];
    
    [_currentStack removeLastObject];
    
	if ([elementName isEqualToString:RSSTagItem]) {
        NewsStory *story = [self storyWithDictionary:_currentItemData];
        NSArray *stories = [_currentStories arrayByAddingObject:story];
        [_currentStories release];
        _currentStories = [stories retain];
        [_currentItemData release];
        _currentItemData = nil;
        
	} else if ([elementName isEqualToString:RSSTagChannel]) {
        [_channelData release];
        _channelData = nil;
    }

    // assume there are 10 stories
    CGFloat progress = 0.3 + fminf(0.7, 0.7 * _currentStories.count / 10);
    [self performSelectorOnMainThread:@selector(reportProgress:)
                           withObject:[NSNumber numberWithFloat:progress]
                        waitUntilDone:NO];
    
    [tinyPool drain];
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    _currentStack = [[NSMutableArray alloc] init];
    _currentStories = [[NSMutableArray alloc] init];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)error {
    [self performSelectorOnMainThread:@selector(parseError:) withObject:error waitUntilDone:NO];
    
    [_currentStories release];
    _currentStories = nil;
    
    [_xmlParser release];
    _xmlParser = nil;
    
    [_currentStack release];
    _currentStack = nil;
    
    _done = YES;
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    [self performSelectorOnMainThread:@selector(reportProgress:)
                           withObject:[NSNumber numberWithFloat:1]
                        waitUntilDone:NO];
    
	[[CoreDataManager sharedManager] saveDataWithTemporaryMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    
    _done = YES;

    [self performSelectorOnMainThread:@selector(parseEnded:) withObject:_currentStories waitUntilDone:YES];
    
    [_currentStories release];
    _currentStories = nil;
    
    [_xmlParser release];
    _xmlParser = nil;

    [_currentStack release];
    _currentStack = nil;
}

#pragma mark XML parser signal functions

- (void)reportProgress:(NSNumber *)percentComplete {
    if ([self.delegate respondsToSelector:@selector(dataController:didMakeProgress:)]) {
        [self.delegate dataController:self didMakeProgress:[percentComplete floatValue]];
    }
}

- (void)parseEnded:(NSArray *)stories {
    NSMutableSet *mergedStories = [NSMutableSet set];
    for (NewsStory *aStory in stories) {
        NSManagedObject *mergedStory = [[[CoreDataManager sharedManager] managedObjectContext] objectWithID:[aStory objectID]];
        [mergedStories addObject:mergedStory];
    }
    self.currentCategory.stories = mergedStories;
    self.currentCategory.lastUpdated = [NSDate date];
    [[CoreDataManager sharedManager] saveData];
    [self fetchStoriesForCategory:self.currentCategory.category_id startId:nil];
}

- (void)parseError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(dataController:didFailWithCategoryId:)]) {
        [self.delegate dataController:self didFailWithCategoryId:self.currentCategory.category_id];
    }
}

@end
