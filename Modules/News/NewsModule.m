#import "NewsModule.h"
#import "StoryListViewController.h"
#import "StoryXMLParser.h"
#import "NewsStory.h"
#import "SpringboardViewController.h"
#import "CoreDataManager.h"

@implementation NewsModule

@synthesize storyListChannelController;
@synthesize xmlParser;

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = NewsOfficeTag;
        self.shortName = @"News";
        self.longName = @"News";
        self.iconName = @"news";
        self.supportsFederatedSearch = YES;
        
        storyListChannelController = [[StoryListViewController alloc] init];
        self.viewControllers = [NSArray arrayWithObject:storyListChannelController];
    }
    return self;
}

- (void)dealloc {
    [storyListChannelController release];
    self.xmlParser = nil;
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
    
    if ([localPath isEqualToString:LocalPathFederatedSearch]) {
        // fedsearch?query
        self.selectedResult = nil;
        storyListChannelController.view;
        storyListChannelController.totalAvailableResults = totalResults;
        [storyListChannelController presentSearchResults:self.searchResults searchText:query];
        [self resetNavStack];
        didHandle = YES;
        
    } else if ([localPath isEqualToString:LocalPathFederatedSearchResult]) {
        // fedresult?rownum
        NSInteger row = [query integerValue];
        
        StoryDetailViewController *detailVC = [[[StoryDetailViewController alloc] init] autorelease];
        self.selectedResult = [self.searchResults objectAtIndex:row];
        detailVC.story = self.selectedResult;
        detailVC.newsController = self;
        self.viewControllers = [NSArray arrayWithObject:detailVC];
        
        didHandle = YES;
        
    } else if ([localPath isEqualToString:NewsLocalPathSearch]) {
        
        
        
    } else if ([localPath isEqualToString:NewsLocalPathBookmarks]) {
        // bookmarks?article
    
    } else {
        // <category>?article

    }
    
    return didHandle;
}

#pragma mark Federated search

- (void)abortSearch {
    if (self.xmlParser) {
        [self.xmlParser abort];
    }
    [super abortSearch];
}

- (void)performSearchForString:(NSString *)searchText {
    // force main news viewController to load here
    // because it fetches things from core data which
    // affects search results we pass to it later on
    storyListChannelController.view;
    
    [super performSearchForString:searchText];
    
    if (self.xmlParser) {
        [self.xmlParser abort];
    }
    self.xmlParser = [[[StoryXMLParser alloc] init] autorelease];
    xmlParser.delegate = self;
    
    [xmlParser loadStoriesforQuery:searchText afterStoryId:0 searchIndex:1 count:10];
}

- (NSString *)titleForSearchResult:(id)result {
    NewsStory *story = (NewsStory *)result;
    return story.title;
}

- (NSString *)subtitleForSearchResult:(id)result {
    NewsStory *story = (NewsStory *)result;
    return story.summary;
}

- (NSInteger)totalSearchResults {
    return totalResults;
}

- (void)loadSearchResultsFromCache {
	// make a predicate for everything with the search flag
    NSPredicate *predicate = nil;
    NSSortDescriptor *relevanceSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"searchResult" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:relevanceSortDescriptor];
    [relevanceSortDescriptor release];
    
	predicate = [NSPredicate predicateWithFormat:@"searchResult > 0"];
    
    NSArray *results = [CoreDataManager objectsForEntity:NewsStoryEntityName matchingPredicate:predicate sortDescriptors:sortDescriptors];
	
    self.searchResults = results;
}

#pragma mark StoryXMLParser delegation

- (void)parserDidMakeConnection:(StoryXMLParser *)parser {
    self.searchProgress = 0.1;
}

- (void)parser:(StoryXMLParser *)parser downloadMadeProgress:(CGFloat)progress {
    self.searchProgress = 0.1 + 0.2 * progress;
}

- (void)parserDidStartParsing:(StoryXMLParser *)parser {
    self.searchProgress = 0.3;
}

- (void)parser:(StoryXMLParser *)parser didMakeProgress:(CGFloat)percentDone {
    self.searchProgress = 0.3 + 0.7 * percentDone * 0.01;
}

- (void)parserDidFinishParsing:(StoryXMLParser *)parser {
    [self loadSearchResultsFromCache];
    totalResults = self.xmlParser.totalAvailableResults;
    self.xmlParser = nil;
}

- (void)parser:(StoryXMLParser *)parser didFailWithDownloadError:(NSError *)error {
    self.searchProgress = 1.0;
    self.searchResults = nil;
    self.xmlParser = nil;
}
                                                                                   
- (void)parser:(StoryXMLParser *)parser didFailWithParseError:(NSError *)error {
    self.searchProgress = 1.0;
    self.searchResults = nil;
    self.xmlParser = nil;
}

#pragma mark NewsControllerDelegate

- (BOOL)canSelectPreviousStory {
    NSInteger currentIndex = [self.searchResults indexOfObject:self.selectedResult];

	if (currentIndex > 0) {
		return YES;
	} else {
		return NO;
	}
}

- (BOOL)canSelectNextStory {
    NSInteger currentIndex = [self.searchResults indexOfObject:self.selectedResult];

	if (currentIndex + 1 < [self.searchResults count]) {
		return YES;
	} else {
		return NO;
	}
}

- (NewsStory *)selectPreviousStory {
	NewsStory *prevStory = nil;
	if ([self canSelectPreviousStory]) {
        NSInteger currentIndex = [self.searchResults indexOfObject:self.selectedResult];
        NSInteger prevIndex = currentIndex - 1;
        self.selectedResult = [self.searchResults objectAtIndex:prevIndex];
        prevStory = (NewsStory *)self.selectedResult;
        
        MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSIndexPath *currentIndexPath = [appDelegate.springboard.searchResultsTableView indexPathForSelectedRow];
        NSInteger selectedRow = prevIndex >= MAX_FEDERATED_SEARCH_RESULTS ? MAX_FEDERATED_SEARCH_RESULTS : prevIndex;
        NSIndexPath *prevIndexPath = [NSIndexPath indexPathForRow:selectedRow inSection:currentIndexPath.section];
		[appDelegate.springboard.searchResultsTableView selectRowAtIndexPath:prevIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
	}
	return prevStory;
}

- (NewsStory *)selectNextStory {
	NewsStory *nextStory = nil;
	if ([self canSelectNextStory]) {
        NSInteger currentIndex = [self.searchResults indexOfObject:self.selectedResult];
        NSInteger nextIndex = currentIndex + 1;
        self.selectedResult = [self.searchResults objectAtIndex:nextIndex];
        nextStory = (NewsStory *)self.selectedResult;
        
        MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSIndexPath *currentIndexPath = [appDelegate.springboard.searchResultsTableView indexPathForSelectedRow];
        NSInteger selectedRow = nextIndex >= MAX_FEDERATED_SEARCH_RESULTS ? MAX_FEDERATED_SEARCH_RESULTS : nextIndex;
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:selectedRow inSection:currentIndexPath.section];
		[appDelegate.springboard.searchResultsTableView selectRowAtIndexPath:nextIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
	}
	return nextStory;
}


@end
