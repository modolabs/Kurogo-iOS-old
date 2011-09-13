#import "NewsModule.h"
#import "StoryListViewController.h"
#import "NewsDataController.h"

@implementation NewsModule

/*
- (id)initWithDictionary:(NSDictionary *)moduleDict {
    
    self = [super initWithDictionary:moduleDict];
    
    // Need to set DataManager and its NewsDataDelegate temporarily to retrieve
    // Categories to support Federated Search
    if (self) {
        
        [self willLaunch]; // does nothing except assign dataManager
        
        _dataManager.delegate = self; // temporarily to fetch category results
        [_dataManager requestCategoriesFromServer]; // request categories from server

    }
    return self;
}
*/

- (void)willLaunch
{
    if (!_dataManager) {
        _dataManager = [[NewsDataController alloc] init];
        _dataManager.moduleTag = self.tag;
        
        // TODO: make a categories request either here or in performSearch
    }
}

- (void)willTerminate
{
    [_dataManager release];
    _dataManager = nil;
}

- (BOOL)requiresKurogoServer
{
    return YES;
}

#pragma mark Navigation

- (NSArray *)registeredPageNames {
    return [NSArray arrayWithObjects:LocalPathPageNameHome, LocalPathPageNameSearch, LocalPathPageNameDetail, nil];
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        StoryListViewController *storyVC = [[[StoryListViewController alloc] initWithNibName:@"StoryListViewController"
                                                                                      bundle:nil] autorelease];
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
        
        NewsStory *story = [params objectForKey:@"story"];
        if (story) { // show only one story
            [detailVC setStory:story];
            [detailVC setMultiplePages:NO];
            
        } else {
            NSArray *stories = [params objectForKey:@"stories"];
            if (stories) {
                [detailVC setStories:stories]; 
                
                NSIndexPath *indexPath = [params objectForKey:@"indexPath"];
                [detailVC setInitialIndexPath:indexPath];
                [detailVC setMultiplePages:YES];
            }
        }

        // TODO: figure out why this (defined in detail vc class) is NewsStory
        NewsStory *category = [params objectForKey:@"category"];
        if (category) {
            [detailVC setCategory:category];
        }
    }
    return vc;
}

// TODO: check if this is being used
- (NewsDataController *)dataManager {
    return _dataManager;
}

- (NSArray *)objectModelNames {
    return [NSArray arrayWithObject:@"News"];
}

#pragma mark Search

- (BOOL)supportsFederatedSearch {
    return YES;
}

- (void)performSearchWithText:(NSString *)searchText
                       params:(NSDictionary *)params
                     delegate:(id<KGOSearchResultsHolder>)delegate
{
    [self willLaunch];
    
    _dataManager.searchDelegate = delegate;
    [_dataManager searchStories:searchText];
}

- (void)didReceiveSearchResults:(NSArray *)results forSearchTerms:(NSString *)searchTerms
{
    [self.searchDelegate searcher:self didReceiveResults:results];
}

- (void)dealloc {
    [_dataManager release];
    _dataManager = nil;
    
    [super dealloc];
}
/*
#pragma mark NewsDataDelegate (to retrieve Categories)

- (void)dataController:(NewsDataController *)controller didRetrieveCategories:(NSArray *)categories{
    
    // Does nothing.
}
*/
@end
