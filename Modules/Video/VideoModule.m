#import "VideoModule.h"
#import "VideoListViewController.h"
#import "VideoDetailViewController.h"
#import "VideoWebViewController.h"

NSString * const KGODataModelNameVideo = @"Video";

@implementation VideoModule

@synthesize dataManager;
@synthesize searchSection;

- (void)willLaunch
{
    [super willLaunch];
    if (!self.dataManager) {
        self.dataManager = [[[VideoDataManager alloc] init] autorelease];
        self.dataManager.moduleTag = self.tag;
    }
}

- (NSArray *)registeredPageNames {
    return [NSArray arrayWithObjects:
            LocalPathPageNameHome,
            LocalPathPageNameDetail,
            LocalPathPageNameWebViewDetail,
            nil];
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        VideoListViewController *listVC = [[[VideoListViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
        listVC.dataManager = self.dataManager;
        vc = listVC;

    } else if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        Video *video = [params objectForKey:@"video"];
        NSString *section = [params objectForKey:@"section"];
        if (video) {
            VideoDetailViewController *detailVC = [[[VideoDetailViewController alloc] initWithVideo:video
                                                                                         andSection:section] autorelease];
            detailVC.dataManager = self.dataManager;
            vc = detailVC;
        }

    } else if ([pageName isEqualToString:LocalPathPageNameWebViewDetail]) {
        Video *video = [params objectForKey:@"video"];
        VideoWebViewController *webVC = [[[VideoWebViewController alloc]
                                          initWithURL:[NSURL URLWithString:video.url]] autorelease];
        webVC.navigationItem.title = video.title; 
        vc = webVC;
    }
    return vc;
}

#pragma mark Data

- (NSArray *)objectModelNames {
    return [NSArray arrayWithObject:KGODataModelNameVideo];
}


#pragma mark Search

- (BOOL)supportsFederatedSearch {
    return YES;
}

- (void)performSearchWithText:(NSString *)searchText 
                       params:(NSDictionary *)params 
                     delegate:(id<KGOSearchResultsHolder>)delegate {
    
    self.searchDelegate = delegate;
    
    // TODO: Get section
    __block VideoModule *blockSelf = self;
    [self.dataManager requestSearchOfSection:self.searchSection 
                                       query:searchText
                                thenRunBlock:^(id result) {
                                    if ([result isKindOfClass:[NSArray class]])
                                    {
                                        [blockSelf.searchDelegate receivedSearchResults:result
                                                                              forSource:blockSelf.shortName];
                                    }
                                }];
}

- (void)dealloc {
    [dataManager release];
    [super dealloc];
}

@end
