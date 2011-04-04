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
        
        if ([params objectForKey:@"story"]) { // show only one story
            NewsStory *story = [params objectForKey:@"story"];
            [(StoryDetailViewController *)vc setStory:story];
            
            [(StoryDetailViewController *)vc setMultiplePages:NO];
        } else if([params objectForKey:@"stories"]) {
            NSArray *stories = [params objectForKey:@"stories"];
            [(StoryDetailViewController *)vc setStories:stories]; 
        
            NSIndexPath *indexPath = [params objectForKey:@"indexPath"];
            [(StoryDetailViewController *)vc setInitialIndexPath:indexPath];
            
            [(StoryDetailViewController *)vc setMultiplePages:YES];
        }
    }
    return vc;
}

- (NSArray *)objectModelNames {
    return [NSArray arrayWithObject:@"News"];
}

#pragma mark Search

- (BOOL)supportsFederatedSearch {
    return YES;
}

- (void)performSearchWithText:(NSString *)searchText params:(NSDictionary *)params delegate:(id<KGOSearchResultsHolder>)delegate {
    
    self.searchDelegate = delegate;
    
    [[NewsDataManager sharedManager] registerDelegate:self];
    [[NewsDataManager sharedManager] search:searchText];
}

- (void) searchResults:(NSArray *)results forSearchTerms:(NSString *)searchTerms {
 
    [self.searchDelegate searcher:self didReceiveResults:results];
}

- (void)dealloc {
    [super dealloc];
}

@end
