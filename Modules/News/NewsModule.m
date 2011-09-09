#import "NewsModule.h"
#import "StoryListViewController.h"
#import "NewsStory.h"
#import "NewsCategory.h"
#import "CoreDataManager.h"
#import "RSSNewsDataController.h"
#import "JSONNewsDataController.h"

@implementation NewsModule


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


- (void)willLaunch
{
    if ((!_dataManager) || (_payload)){ // if _payload then it could reassign the default dataManager.
        NSString *format = [_payload objectForKey:@"format"];
        if ([format isEqualToString:@"rss"]) {
            _controllerClass = NewsDataControllerClassRSS;
        }
        
        switch (_controllerClass) {
            case NewsDataControllerClassRSS:
                _dataManager = [[RSSNewsDataController alloc] init];
                _dataManager.moduleTag = self.tag;
                break;
            case NewsDataControllerClassJSON:
            default:
                _dataManager = [[JSONNewsDataController alloc] init];
                _dataManager.moduleTag = self.tag;
                break;
        }
        
        if (_payload) {
            [_dataManager readFeedData:_payload];
            [_payload release];
            _payload = nil;
        }
    }
}

- (void)willTerminate
{
    [_dataManager release];
    _dataManager = nil;
}

- (void)evaluateInitialiationPayload:(NSDictionary *)payload
{
    [_payload release];
    _payload = [payload retain];
}

- (BOOL)requiresKurogoServer
{
    if (_dataManager) {
        return [_dataManager requiresKurogoServer];
    }
    return NO;
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

- (void)didReceiveSearchResults:(NSArray *)results forSearchTerms:(NSString *)searchTerms {
 
    [self.searchDelegate searcher:self didReceiveResults:results];
}

- (void)dealloc {
    [_dataManager release];
    _dataManager = nil;
    
    [super dealloc];
}

#pragma mark NewsDataDelegate (to retrieve Categories)

- (void)dataController:(NewsDataController *)controller didRetrieveCategories:(NSArray *)categories{
    
    // Does nothing.
}

@end
