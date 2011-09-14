#import "NewsModule.h"
#import "StoryListViewController.h"
#import "NewsDataController.h"

@implementation NewsModule

- (void)willLaunch
{
    if (!_dataManager) {
        _dataManager = [[NewsDataController alloc] init];
        _dataManager.moduleTag = self.tag;
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
    self.searchDelegate = delegate;

    [_searchText release];
    _searchText = [searchText retain];

    _dataManager.delegate = self;
    [_dataManager fetchCategories];
}

- (void)didReceiveSearchResults:(NSArray *)results forSearchTerms:(NSString *)searchTerms
{
    [self.searchDelegate searcher:self didReceiveResults:results];
    self.searchDelegate = nil;
}

- (void)dealloc {
    [_dataManager release];
    _dataManager = nil;

    [_searchText release];
    _searchText = nil;
    
    [super dealloc];
}

#pragma mark NewsDataDelegate (to retrieve Categories)

- (void)dataController:(NewsDataController *)controller didRetrieveCategories:(NSArray *)categories
{
    if (self.searchDelegate) {
        _dataManager.searchDelegate = self.searchDelegate;
        self.searchDelegate = nil;
        [_dataManager searchStories:_searchText];
        [_searchText release];
        _searchText = nil;
    }
}

@end
