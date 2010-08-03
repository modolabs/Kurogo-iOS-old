#import "StoryXMLParser.h"
#import "NewsStory.h"
#import "CoreDataManager.h"
#import "MIT_MobileAppDelegate.h"
#import "JSONAPIRequest.h"
#import "NewsCategory.h"
#import "NewsImage.h"

@interface StoryXMLParser (Private)

- (void)detachAndParseURL:(NSURL *)url;
- (void)downloadAndParse:(NSURL *)url;
- (NSArray *)itemWhitelist;
- (NSArray *)imageWhitelist;
- (NewsImage *)imageWithDictionary:(NSDictionary *)imageDict;
//- (NewsImageRep *)imageRepForURLString:(NSString *)urlString;

- (void)didStartDownloading;
- (void)didStartParsing;
- (void)reportProgress:(NSNumber *)percentComplete;
- (void)parseEnded;
- (void)downloadError:(NSError *)error;
- (void)parseError:(NSError *)error;

- (NSInteger)idForCategoryString:(NSString *)aString;
- (NSString *)stringForCategoryID:(NSInteger)anID;
- (NewsCategory *)categoryForID:(NSInteger)anID;
- (NewsCategory *)categoryForString:(NSString *)aString;

@end


@implementation StoryXMLParser

@synthesize delegate;
@synthesize parsingTopStories;
@synthesize isSearch;
@synthesize loadingMore;
@synthesize totalAvailableResults;
@synthesize connection;
@synthesize xmlParser;
@synthesize currentElement;
@synthesize currentStack;
@synthesize currentContents;
@synthesize currentImage;
@synthesize newStories;
@synthesize downloadAndParsePool;

NSString * const NewsTagChannel         = @"channel";

NSString * const NewsTagItem            = @"item";
NSString * const NewsTagTitle           = @"title";
NSString * const NewsTagAuthor          = @"harvard:author";
NSString * const NewsTagAffiliation     = @"harvard:affiliation";
NSString * const NewsTagCategory        = @"category";
NSString * const NewsTagLink            = @"link";
NSString * const NewsTagStoryId         = @"harvard:WPID";
NSString * const NewsTagFeatured        = @"harvard:featured";
NSString * const NewsTagFeaturedImage   = @"harvard:featured_photo";
NSString * const NewsTagSummary         = @"description";
NSString * const NewsTagPostDate        = @"pubDate";
NSString * const NewsTagBody            = @"content:encoded";

NSString * const NewsTagImage           = @"image";
NSString * const NewsTagImageTitle      = @"title";
NSString * const NewsTagImageLink       = @"link";
NSString * const NewsTagThumbnailURL    = @"url";
NSString * const NewsTagImageWidth      = @"width";
NSString * const NewsTagImageHeight     = @"height";
NSString * const NewsTagFullURL         = @"url";

#pragma mark Categories

- (NewsCategory *)categoryForString:(NSString *)aString {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title like %@", aString];
    return [[CoreDataManager objectsForEntity:NewsCategoryEntityName matchingPredicate:predicate] lastObject];
}

- (NSInteger)idForCategoryString:(NSString *)aString {
    NSInteger result = NSNotFound;
    NewsCategory *category = [self categoryForString:aString];
    if (category) {
        result = [category.category_id intValue];
    }
    return result;
}

- (NewsCategory *)categoryForID:(NSInteger)anID {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category_id == %d", anID];
    return [[CoreDataManager objectsForEntity:NewsCategoryEntityName matchingPredicate:predicate] lastObject];
}

- (NSString *)stringForCategoryID:(NSInteger)anID {
    NSString *result = nil;
    NewsCategory *category = [self categoryForID:anID];
    if (category) {
        result = category.title;
    }
    return result;
}

#pragma mark -

- (id) init
{
    self = [super init];
    if (self != nil) {
        delegate = nil;
		thread = nil;
        expectedStoryCount = 0;
        parsingTopStories = NO;
        connection = nil;
        currentElement = nil;
        currentStack = nil;
        currentContents = nil;
        currentImage = nil;
        newStories = nil;
        downloadAndParsePool = nil;
        done = NO;
		isSearch = NO;
		loadingMore = NO;
		totalAvailableResults = 0;
        parseSuccessful = NO;
        shouldAbort = NO;
    }
    return self;
}

- (void)dealloc {
	if (![thread isFinished]) {
		NSLog(@"***** %s called before parsing finished", __PRETTY_FUNCTION__);
	}
	[thread release];
	thread = nil;
    self.delegate = nil;
    self.connection = nil;
	self.xmlParser = nil;
    self.newStories = nil;
    self.currentElement = nil;
    self.currentStack = nil;
    self.currentContents = nil;
    self.currentImage = nil;
	self.downloadAndParsePool = nil;
    [super dealloc];
}

- (void)loadStoriesForCategory:(NSInteger)category afterStoryId:(NSInteger)storyId count:(NSInteger)count {
	self.isSearch = NO;
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:3];
    [params setObject:@"news" forKey:@"module"];
    
    if (category != 0) {
        [params setObject:[NSString stringWithFormat:@"%d", category] forKey:@"channel"];
    } else {
        parsingTopStories = TRUE;
    }
	self.loadingMore = NO;
    if (storyId != 0) {
		self.loadingMore = YES;
        [params setObject:[NSString stringWithFormat:@"%d", storyId] forKey:@"storyId"];
    }

    NSURL *fullURL = [JSONAPIRequest buildURL:params queryBase:MITMobileWebAPIURLString];
    
    expectedStoryCount = 10; // if the server is ever made to support a range param, set this to count instead
    
	[self detachAndParseURL:fullURL];
}

- (void)loadStoriesforQuery:(NSString *)query afterStoryId:(NSInteger)storyId count:(NSInteger)count {
	self.isSearch = YES;
	self.loadingMore = (storyId == 0) ? NO : YES;
	
	// before getting new results, clear old search results if this is a new search request
	if (self.isSearch && !self.loadingMore) {
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"searchResult == YES"];
		NSArray *results = [CoreDataManager objectsForEntity:NewsStoryEntityName matchingPredicate:predicate];
		for (NewsStory *aStory in results) {
			aStory.searchResult = NO;
		}
		[CoreDataManager saveDataWithTemporaryMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
	}
    
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"news", @"module",
                                   @"search", @"command",
                                   [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], @"q",
                                   nil];
    if (self.loadingMore) {
        [params setObject:[NSString stringWithFormat:@"%d", storyId] forKey:@"storyId"];
    }
    
    NSURL *fullURL = [JSONAPIRequest buildURL:params queryBase:MITMobileWebAPIURLString];
    
    expectedStoryCount = count;
    
	[self detachAndParseURL:fullURL];
}

- (void)detachAndParseURL:(NSURL *)url {
	if (thread) {
		NSLog(@"***** %s called twice on the same instance", __PRETTY_FUNCTION__);
	}
	thread = [[NSThread alloc] initWithTarget:self selector:@selector(downloadAndParse:) object:url];
	[thread start];
}

- (void)abort {
    shouldAbort = YES;
	[thread cancel];
}

// should be spawned on a separate thread
- (void)downloadAndParse:(NSURL *)url {
	self.downloadAndParsePool = [[NSAutoreleasePool alloc] init];
	done = NO;
    parseSuccessful = NO;
    
    self.connection = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
    self.newStories = [NSMutableArray array];
    
    BOOL requestStarted = [connection requestDataFromURL:url];
	if (requestStarted) {
        [self performSelectorOnMainThread:@selector(didStartDownloading) withObject:nil waitUntilDone:NO];
		do {
			if ([[NSThread currentThread] isCancelled]) {
				if (self.connection) {
					[self.connection cancel];
					self.connection = nil;
				}
				if (self.xmlParser) {
					[self.xmlParser abortParsing];
					self.xmlParser = nil;
				}
				break;
			}
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
		} while (!done);
	} else {
        [self performSelectorOnMainThread:@selector(downloadError:) withObject:nil waitUntilDone:NO];
    }
    [downloadAndParsePool release];
	self.downloadAndParsePool = nil;
}

- (void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
	if (shouldAbort) {
		return;
	}
    self.connection = nil;
    self.xmlParser = [[NSXMLParser alloc] initWithData:data];
	self.xmlParser.delegate = self;
    self.currentContents = [NSMutableDictionary dictionary];
    self.currentStack = [NSMutableArray array];
	[self.xmlParser parse];
	self.xmlParser = nil;
    self.currentStack = nil;
	done = YES;
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError:(NSError *)error {
	[self performSelectorOnMainThread:@selector(downloadError:) withObject:error waitUntilDone:NO];
	done = YES;
}

#pragma mark NSXMLParser delegation

- (NSArray *)itemWhitelist {
    static NSArray *itemWhitelist;
    
    if (!itemWhitelist) {
        itemWhitelist = [[NSArray arrayWithObjects:
                          NewsTagTitle,
                          NewsTagAuthor,
                          NewsTagAffiliation,
                          NewsTagCategory,
                          NewsTagLink,
                          NewsTagStoryId,
                          NewsTagFeatured,
                          NewsTagFeaturedImage,
                          NewsTagSummary,
                          NewsTagPostDate,
                          NewsTagBody,
                          nil] retain];
    }
    return itemWhitelist;
}

- (NSArray *)imageWhitelist {
    static NSArray *imageWhitelist;
    
    if (!imageWhitelist) {
        imageWhitelist = [[NSArray arrayWithObjects:
                           NewsTagImageTitle,
                           NewsTagImageLink,
                           NewsTagThumbnailURL,
                           NewsTagImageWidth,
                           NewsTagImageHeight, nil] retain];
    }
    return imageWhitelist;
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict {
    
    self.currentElement = elementName;
	if ([elementName isEqualToString:NewsTagItem]) {
        if ([[currentContents allValues] count] > 0) {
            NSLog(@"%s warning: found a nested <item> in the News XML.", __PRETTY_FUNCTION__);
            [currentContents removeAllObjects];
        }
        NSArray *whitelist = [self itemWhitelist];
        for (NSString *key in whitelist) {
            [currentContents setObject:[NSMutableString string] forKey:key];
        }
        [currentCategories release];
        currentCategories = [[NSMutableArray alloc] initWithCapacity:5];
	} else if ([elementName isEqualToString:NewsTagImage]) {
        // prep new image element
        self.currentImage = [NSMutableDictionary dictionary];
        NSArray *whitelist = [self imageWhitelist];
        for (NSString *key in whitelist) {
            [currentImage setObject:[NSMutableString string] forKey:key];
        }
        [currentContents setObject:currentImage forKey:NewsTagImage];
        
    } else if ([elementName isEqualToString:NewsTagChannel]) {
        if (!self.loadingMore) {
            self.totalAvailableResults = [[attributeDict objectForKey:@"items"] intValue];
        }
    }
    [currentStack addObject:elementName];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (shouldAbort) {
        [parser abortParsing];
        return;
    }
    
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    NSMutableDictionary *currentDict = nil;
    NSArray *whitelist = nil;
    
    if ([currentStack indexOfObject:NewsTagImage] != NSNotFound) {
        currentDict = currentImage;
        whitelist = [self imageWhitelist];
    } else if ([currentStack indexOfObject:NewsTagItem] != NSNotFound) {
        currentDict = currentContents;
        whitelist = [self itemWhitelist];
        if ([[currentStack lastObject] isEqualToString:NewsTagCategory]) {
            // TODO: make a more generalized function to handle html entities
            string = [string stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
            NewsCategory *category = [self categoryForString:string];
            if (!category) {
                NSPredicate *truePredicate = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
                NSInteger numCategories = [[CoreDataManager objectsForEntity:NewsCategoryEntityName matchingPredicate:truePredicate] count];
                
                category = [CoreDataManager insertNewObjectForEntityForName:NewsCategoryEntityName];
                category.title = string;
                category.category_id = [NSNumber numberWithInt:numCategories];
                [CoreDataManager saveData];
            }
            
            [currentCategories addObject:category];
        }
    } else {
        return;
    }
    
    if ([string length] > 0 && [whitelist containsObject:currentElement]) {
        NSMutableString *value = [currentDict objectForKey:currentElement];
        [value appendString:string];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    NSAutoreleasePool *tinyPool = [[NSAutoreleasePool alloc] init];
    
    [currentStack removeLastObject];

	if ([elementName isEqualToString:NewsTagItem]) {
        // use existing story if it's already in the db
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"story_id == %d", [[currentContents objectForKey:NewsTagStoryId] integerValue]];
        NewsStory *story = [[CoreDataManager objectsForEntity:NewsStoryEntityName matchingPredicate:predicate] lastObject];
        // otherwise create new
        if (!story) {
            story = (NewsStory *)[CoreDataManager insertNewObjectForEntityForName:NewsStoryEntityName];
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
        [formatter setDateFormat:@"EEE, d MMM y HH:mm:ss zzz"];
        [formatter setTimeZone:[NSTimeZone localTimeZone]];
        NSDate *postDate = [formatter dateFromString:[currentContents objectForKey:NewsTagPostDate]];
        [formatter release];
        
        story.story_id = [NSNumber numberWithInteger:[[currentContents objectForKey:NewsTagStoryId] integerValue]];
        story.postDate = postDate;
        story.title = [currentContents objectForKey:NewsTagTitle];
        story.link = [currentContents objectForKey:NewsTagLink];
        story.author = [NSString stringWithFormat:@"%@, %@",
                        [currentContents objectForKey:NewsTagAuthor],
                        [currentContents objectForKey:NewsTagAffiliation]];
        story.summary = [currentContents objectForKey:NewsTagSummary];
        story.body = [currentContents objectForKey:NewsTagBody];
        
        story.categories = [NSSet setWithSet:currentCategories];
        if (parsingTopStories) {
            // because NewsStory objects are shared between categories, only set this to YES, never revert it to NO
            story.topStory = [NSNumber numberWithBool:parsingTopStories];
        }
        story.searchResult = [NSNumber numberWithBool:isSearch]; // gets reset to NO before every search
        
        story.featured = [NSNumber numberWithBool:![[currentContents objectForKey:NewsTagFeatured] isEqualToString:@"no"]];
        
        NSDictionary *imageDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [currentContents objectForKey:NewsTagFeaturedImage], NewsTagFullURL,
                                   [NSNumber numberWithInt:320], NewsTagImageWidth,
                                   [NSNumber numberWithInt:240], NewsTagImageHeight,
                                   nil];
        story.featuredImage = [self imageWithDictionary:imageDict];
        story.featuredImage.featuredParent = story;
        story.thumbImage = [self imageWithDictionary:[currentContents objectForKey:NewsTagImage]];
        story.thumbImage.thumbParent = story;
        
        [self performSelectorOnMainThread:@selector(reportProgress:) withObject:[NSNumber numberWithFloat:[newStories count] / (0.01 * expectedStoryCount)] waitUntilDone:NO];
        
        [newStories addObject:story];
        
        // prepare for next item
        [currentContents removeAllObjects];
	}
    [tinyPool release];
    
}

- (NewsImage *)imageWithDictionary:(NSDictionary *)dict {
    NewsImage *newsImage = nil;
    NSNumber *width = [NSNumber numberWithInt:[[dict objectForKey:NewsTagImageWidth] intValue]];
    NSNumber *height = [NSNumber numberWithInt:[[dict objectForKey:NewsTagImageWidth] intValue]];
    NSString *link = [dict objectForKey:NewsTagImageLink];
    NSString *title = [dict objectForKey:NewsTagImageTitle];
    NSString *url = [dict objectForKey:NewsTagFullURL];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"url == %@", url];
    newsImage = [[CoreDataManager objectsForEntity:NewsImageEntityName matchingPredicate:predicate] lastObject];
    if (!newsImage) {
        newsImage = [CoreDataManager insertNewObjectForEntityForName:NewsImageEntityName];
    }
    
    newsImage.width = width;
    newsImage.height = height;
    newsImage.url = url;
    
    if (title != nil) {
        newsImage.title = title;
    }
    
    if (link != nil) {
        newsImage.link = link;
    }
    
    return newsImage;
}

- (void)reportProgress:(NSNumber *)percentComplete {
    if ([self.delegate respondsToSelector:@selector(parser:didMakeProgress:)]) {
        [self.delegate parser:self didMakeProgress:[percentComplete floatValue]];
    }
}

#pragma mark -
#pragma mark StoryXMLParser delegation

- (void)didStartDownloading {
	if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parserDidStartDownloading:)]) {
		[self.delegate parserDidStartDownloading:self];	
	}
}

- (void)didStartParsing {
	if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parserDidStartParsing:)]) {
		[self.delegate parserDidStartParsing:self];	
	}
}

- (void)parseEnded {
	if (parseSuccessful && self.delegate != nil && [self.delegate respondsToSelector:@selector(parserDidFinishParsing:)]) {
		[self.delegate parserDidFinishParsing:self];
	}
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)error {
    [self performSelectorOnMainThread:@selector(parseError:) withObject:error waitUntilDone:NO];
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    [self performSelectorOnMainThread:@selector(didStartParsing) withObject:nil waitUntilDone:NO];
}
         
- (void)parserDidEndDocument:(NSXMLParser *)parser {
    
    if (shouldAbort) {
        [parser abortParsing];
        return;
    }
    
    parseSuccessful = YES;
    
	[CoreDataManager saveDataWithTemporaryMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    if (parseSuccessful) {
        [self performSelectorOnMainThread:@selector(parseEnded) withObject:nil waitUntilDone:NO];
    }
}

- (void)downloadError:(NSError *)error {
    parseSuccessful = NO;
	if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parser:didFailWithDownloadError:)]) {
		[self.delegate parser:self didFailWithDownloadError:error];	
	}
}

- (void)parseError:(NSError *)error {
    NSLog(@"parser failed with error %@", [error description]);
    parseSuccessful = NO;
	if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parser:didFailWithParseError:)]) {
		[self.delegate parser:self didFailWithParseError:error];	
	}
}

@end
