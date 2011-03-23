#import "NewsModule.h"
#import "StoryListViewController.h"
#import "NewsStory.h"
#import "CoreDataManager.h"

@implementation NewsModule

@synthesize storyListChannelController;
#pragma mark Navigation

- (NSArray *)registeredPageNames {
    return [NSArray arrayWithObjects:LocalPathPageNameHome, LocalPathPageNameSearch, LocalPathPageNameDetail, nil];
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [[[StoryListViewController alloc] init] autorelease];
    } else if([pageName isEqualToString:LocalPathPageNameDetail]) {
        vc = [[[StoryDetailViewController alloc] init] autorelease];
        
        NSArray *stories = [params objectForKey:@"stories"];
        [(StoryDetailViewController *)vc setStories:stories]; 
        
        NSIndexPath *indexPath = [params objectForKey:@"indexPath"];
        [(StoryDetailViewController *)vc setInitialIndexPath:indexPath];
    }
    return vc;
}

- (NSArray *)objectModelNames {
    return [NSArray arrayWithObject:@"News"];
}

- (void)dealloc {
    [super dealloc];
}

/*
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
        
        KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
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
        
        KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
        NSIndexPath *currentIndexPath = [appDelegate.springboard.searchResultsTableView indexPathForSelectedRow];
        NSInteger selectedRow = nextIndex >= MAX_FEDERATED_SEARCH_RESULTS ? MAX_FEDERATED_SEARCH_RESULTS : nextIndex;
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:selectedRow inSection:currentIndexPath.section];
		[appDelegate.springboard.searchResultsTableView selectRowAtIndexPath:nextIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
	}
	return nextStory;
}
*/

@end
