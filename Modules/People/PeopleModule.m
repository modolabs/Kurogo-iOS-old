#import "PeopleModule.h"
#import "PeopleHomeViewController.h"
#import "PeopleDetailsViewController.h"
#import "KGOPersonWrapper.h"
#import "KGOSearchModel.h"

@implementation PeopleModule

@synthesize request;

#pragma mark Module state

- (void)willTerminate
{
    [KGOPersonWrapper clearOldResults];
}

#pragma mark Search

- (BOOL)supportsFederatedSearch {
    return YES;
}

- (void)performSearchWithText:(NSString *)searchText params:(NSDictionary *)params delegate:(id<KGOSearchResultsHolder>)delegate {
    self.searchDelegate = delegate;

    NSMutableDictionary *mutableParams = nil;
    if (params) {
        mutableParams = [[params mutableCopy] autorelease];
    } else {
        mutableParams = [NSMutableDictionary dictionary];
    }

    if (searchText) {
        [mutableParams setObject:searchText forKey:@"q"];
    }
    
    self.request = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                   module:self.tag
                                                                     path:@"search"
                                                                   params:mutableParams];
    self.request.expectedResponseType = [NSDictionary class];
    if (self.request)
        [self.request connect];
}

#pragma mark Data

- (NSArray *)objectModelNames {
    return [NSArray arrayWithObject:@"PeopleDataModel"];
}

#pragma mark Navigation

- (NSArray *)registeredPageNames {
    return [NSArray arrayWithObjects:LocalPathPageNameHome, LocalPathPageNameSearch, LocalPathPageNameDetail, nil];
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [[[PeopleHomeViewController alloc] init] autorelease];
        
    } else if ([pageName isEqualToString:LocalPathPageNameSearch]) {
        vc = [[[PeopleHomeViewController alloc] init] autorelease];

        NSString *searchText = [params objectForKey:@"q"];
        if (searchText) {
            [(PeopleHomeViewController *)vc setSearchTerms:searchText];
        }
        
    } else if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        KGOPersonWrapper *person = nil;
        NSString *uid = [params objectForKey:@"uid"];
        if (uid) {
            person = [KGOPersonWrapper personWithUID:uid];
        } else {
            person = [params objectForKey:@"person"];
        }
        
        if (person) {
            vc = [[[PeopleDetailsViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
            
            // this is only set if the page is called from search or recents
            KGODetailPager *pager = [params objectForKey:@"pager"];
            if (pager) {
                [(PeopleDetailsViewController *)vc setPager:pager];
            }
            
            [(PeopleDetailsViewController *)vc setPerson:person];
        }
    }
    return vc;
}

#pragma mark KGORequestDelegate

- (void)requestWillTerminate:(KGORequest *)request {
    self.request = nil;
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result {
    self.request = nil;

    NSArray *resultArray = [result arrayForKey:@"results"];
    NSMutableArray *searchResults = [NSMutableArray arrayWithCapacity:[(NSArray *)resultArray count]];
    for (id aResult in resultArray) {
        NSLog(@"%@", [aResult description]);
        KGOPersonWrapper *person = [[[KGOPersonWrapper alloc] initWithDictionary:aResult] autorelease];
        if (person)
            [searchResults addObject:person];
    }
    [self.searchDelegate searcher:self didReceiveResults:searchResults];
}

#pragma mark -

- (void)dealloc
{
    [self.request cancel];
    self.request = nil;
    
	[super dealloc];
}

@end

