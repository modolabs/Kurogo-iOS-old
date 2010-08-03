#import "NewsModule.h"
#import "StoryListViewController.h"
#import "StoryXMLParser.h"
#import "NewsStory.h"
#import "SpringboardViewController.h"
#import "CoreDataManager.h"

@implementation NewsModule

@synthesize storyListChannelController;
@synthesize xmlParser, stories;

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = NewsOfficeTag;
        self.shortName = @"News";
        self.longName = @"News Office";
        self.iconName = @"news";
        self.supportsFederatedSearch = YES;
        
        storyListChannelController = [[StoryListViewController alloc] init];
        self.viewControllers = [NSArray arrayWithObject:storyListChannelController];
    }
    return self;
}

- (void)dealloc {
    [storyListChannelController release];
    [super dealloc];
}

#pragma mark State and url

- (void)resetNavStack {
    self.viewControllers = [NSArray arrayWithObject:storyListChannelController];
}

NSString * const NewsLocalPathSearch = @"search";
NSString * const NewsLocalPathBookmarks = @"bookmarks";

- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query {
    BOOL didHandle = NO;
    //NSMutableArray *mutableVCs = [self.viewControllers mutableCopy];
    
    if ([localPath isEqualToString:NewsLocalPathSearch]) {
        // search?q=query&a=article

        NSArray *queryKeys = [query componentsSeparatedByString:@"&"];
        NSString *searchTerms = nil;  // nil if this is federated search
        NSString *article = nil; // nil unless they are viewing an article
        NSInteger row = NSNotFound;
        for (NSString *qKey in queryKeys) {
            NSArray *qValues = [qKey componentsSeparatedByString:@"="];
            if ([qValues count] == 2) {
                if ([[qValues objectAtIndex:0] isEqualToString:@"q"]) {
                    searchTerms = [qValues objectAtIndex:1];
                } else if ([[qValues objectAtIndex:0] isEqualToString:@"a"]) {
                    article = [qValues objectAtIndex:1];
                } else if ([[qValues objectAtIndex:0] isEqualToString:@"row"]) {
                    row = [[qValues objectAtIndex:1] intValue];
                }
            }
        }
        
        if (row != NSNotFound) { // federated search
            StoryDetailViewController *detailVC = [[StoryDetailViewController alloc] init];
            detailVC.newsController = self;
            self.viewControllers = [NSArray arrayWithObject:detailVC];
        }
        
        if (searchTerms != nil) {
            [storyListChannelController showSearchBar];
            [storyListChannelController unfocusSearchBar];
            //[storyListChannelController loadSearchResultsFromServer:NO forQuery:searchTerms];         
        }
        
        if (article != nil) {
            //StoryDetailViewController *detailVC = [[StoryDetailViewController alloc] init];
        }
        
        didHandle = YES;
        
    } else if ([localPath isEqualToString:NewsLocalPathBookmarks]) {
        // bookmarks?article
    
    } else {
        // <category>?article

    }
    
    return didHandle;
}

- (void)performSearchForString:(NSString *)searchText {
    self.stories = [NSArray array];
    
    if (self.xmlParser) {
        [self.xmlParser abort];
    }
    self.xmlParser = [[[StoryXMLParser alloc] init] autorelease];
    xmlParser.delegate = self;
    
    [xmlParser loadStoriesforQuery:searchText afterStoryId:0 count:10];   
}

- (NSString *)titleForSearchResult:(id)result {
    NewsStory *story = (NewsStory *)result;
    return story.title;
}

- (NSString *)subtitleForSearchResult:(id)result {
    NewsStory *story = (NewsStory *)result;
    return [story.postDate description];
}

- (void)parserDidStartDownloading:(StoryXMLParser *)parser {
    self.searchProgress = 0.1;
}

- (void)parserDidStartParsing:(StoryXMLParser *)parser {
    self.searchProgress = 0.3;
}

- (void)parser:(StoryXMLParser *)parser didMakeProgress:(CGFloat)percentDone {
    self.searchProgress = 0.3 + 0.7 * percentDone * 0.01;
}

- (void)parserDidFinishParsing:(StoryXMLParser *)parser {
    [self loadSearchResultsFromCache];
}

- (BOOL)canSelectPreviousStory {
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSIndexPath *currentIndexPath = [appDelegate.springboard.searchResultsTableView indexPathForSelectedRow];

	if (currentIndexPath.row > 0) {
		return YES;
	} else {
		return NO;
	}
}

- (BOOL)canSelectNextStory {
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSIndexPath *currentIndexPath = [appDelegate.springboard.searchResultsTableView indexPathForSelectedRow];

	if (currentIndexPath.row + 1 < [self.stories count]) {
		return YES;
	} else {
		return NO;
	}
}

- (NewsStory *)selectPreviousStory {
	NewsStory *prevStory = nil;
	if ([self canSelectPreviousStory]) {
        MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSIndexPath *currentIndexPath = [appDelegate.springboard.searchResultsTableView indexPathForSelectedRow];
		NSIndexPath *prevIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row - 1 inSection:currentIndexPath.section];
		prevStory = [self.stories objectAtIndex:prevIndexPath.row];
		[appDelegate.springboard.searchResultsTableView selectRowAtIndexPath:prevIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
	}
	return prevStory;
}

- (NewsStory *)selectNextStory {
	NewsStory *nextStory = nil;
	if ([self canSelectNextStory]) {
        MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSIndexPath *currentIndexPath = [appDelegate.springboard.searchResultsTableView indexPathForSelectedRow];
		NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row + 1 inSection:currentIndexPath.section];
		nextStory = [self.stories objectAtIndex:nextIndexPath.row];
		[appDelegate.springboard.searchResultsTableView selectRowAtIndexPath:nextIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
	}
	return nextStory;
}

- (void)loadSearchResultsFromCache {
	// make a predicate for everything with the search flag
    NSPredicate *predicate = nil;
    NSSortDescriptor *postDateSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"postDate" ascending:NO];
    NSSortDescriptor *storyIdSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"story_id" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:postDateSortDescriptor, storyIdSortDescriptor, nil];
    [storyIdSortDescriptor release];
    [postDateSortDescriptor release];
    
	predicate = [NSPredicate predicateWithFormat:@"searchResult == YES"];
    
    NSArray *results = [CoreDataManager objectsForEntity:NewsStoryEntityName matchingPredicate:predicate sortDescriptors:sortDescriptors];
    //NSInteger resultsCount = [results count];
	
    self.searchResults = results;
}


@end
