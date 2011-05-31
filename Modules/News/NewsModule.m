#import "NewsModule.h"
#import "StoryListViewController.h"
#import "NewsStory.h"
#import "CoreDataManager.h"

@implementation NewsModule

- (void)willLaunch
{
    if (!_dataManager) {
        _dataManager = [[NewsDataManager alloc] init];
        _dataManager.moduleTag = self.tag;
    }
}

#pragma mark Navigation

- (NSArray *)registeredPageNames {
    return [NSArray arrayWithObjects:LocalPathPageNameHome, LocalPathPageNameSearch, LocalPathPageNameDetail, nil];
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        StoryListViewController *storyVC = [[[StoryListViewController alloc] init] autorelease];
        storyVC.dataManager = _dataManager;
        _dataManager.delegate = storyVC;
        vc = storyVC;
        
        if ([params objectForKey:@"category"]) {
            NewsCategory *category = [params objectForKey:@"category"];
            [(StoryListViewController *)vc setActiveCategoryId:category.category_id];
        }
        
    } else if([pageName isEqualToString:LocalPathPageNameDetail]) {
        StoryDetailViewController *detailVC = [[[StoryDetailViewController alloc] init] autorelease];
        detailVC.dataManager = _dataManager;
        vc = detailVC;
        
        if ([params objectForKey:@"story"]) { // show only one story
            NewsStory *story = [params objectForKey:@"story"];
            [detailVC setStory:story];
            [detailVC setMultiplePages:NO];
            
        } else if([params objectForKey:@"stories"]) {
            NSArray *stories = [params objectForKey:@"stories"];
            [detailVC setStories:stories]; 
        
            NSIndexPath *indexPath = [params objectForKey:@"indexPath"];
            [detailVC setInitialIndexPath:indexPath];
            [detailVC setMultiplePages:YES];
        }
        
        if ([params objectForKey:@"category"]) {
            [detailVC setCategory:[params objectForKey:@"category"]];
        }
    }
    return vc;
}

// TODO: check if this is being used
- (NewsDataManager *)dataManager {
    return _dataManager;
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
    
    [self.dataManager search:searchText];
}

- (void)didReceiveSearchResults:(NSArray *)results forSearchTerms:(NSString *)searchTerms {
 
    [self.searchDelegate searcher:self didReceiveResults:results];
}

- (void)dealloc {
    [_dataManager release];
    _dataManager = nil;
    
    [super dealloc];
}

@end
