#import "PeopleModule.h"
#import "PeopleHomeViewController.h"
#import "PeopleDetailsViewController.h"
#import "PeopleGroupContactViewController.h"
#import "PeopleModel.h"
#import "KGOSearchModel.h"

@implementation PeopleModule

@synthesize request;

#pragma mark Module state

- (void)willTerminate
{
    [KGOPersonWrapper clearOldResults];
}

- (BOOL)requiresKurogoServer
{
    // if no contact info has ever been imported, this module is not useful without connection
    NSArray *contacts = [PersonContact directoryContacts];
    return contacts.count <= 0;
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
    [self.request connect];
}

#pragma mark Data

- (NSArray *)objectModelNames {
    return [NSArray arrayWithObject:@"PeopleDataModel"];
}

#pragma mark Navigation

- (NSArray *)registeredPageNames {
    return [NSArray arrayWithObjects:
            LocalPathPageNameHome,
            LocalPathPageNameSearch,
            LocalPathPageNameDetail,
            LocalPathPageNameItemList,
            nil];
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        PeopleHomeViewController *homeVC = [[[PeopleHomeViewController alloc] init] autorelease];
        homeVC.module = self;
        vc = homeVC;
        
    } else if ([pageName isEqualToString:LocalPathPageNameSearch]) {
        PeopleHomeViewController *homeVC = [[[PeopleHomeViewController alloc] init] autorelease];
        homeVC.module = self;

        NSString *searchText = [params objectForKey:@"q"];
        if (searchText) {
            homeVC.federatedSearchTerms = searchText;
        }
        
        NSArray *searchResults = [params objectForKey:@"searchResults"];
        if (searchResults) {
            homeVC.federatedSearchResults = searchResults;
        }
        
        vc = homeVC;
        
    } else if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        KGOPersonWrapper *person = nil;
        NSString *uid = [params objectForKey:@"uid"];
        if (uid) {
            person = [KGOPersonWrapper personWithUID:uid];
            person.moduleTag = self.tag;
        } else {
            person = [params objectForKey:@"person"];
            
            if (nil == person.identifier) {
                NSString * identifierString = [NSString stringWithFormat:@"%@-%@", person.name, [[NSDate date] description]];
                person.identifier = identifierString;
            }
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
    } else if ([pageName isEqualToString:LocalPathPageNameItemList]) {
        PersonContact *contact = [params objectForKey:@"contact"];
        PeopleGroupContactViewController *pgcvc = [[[PeopleGroupContactViewController alloc] initWithGroup:contact.group] autorelease];
        pgcvc.module = self;
        vc.navigationItem.title = contact.title;
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
        KGOPersonWrapper *person = [[[KGOPersonWrapper alloc] initWithDictionary:aResult] autorelease];
        if (person) {
            person.moduleTag = self.tag;
            [searchResults addObject:person];
        }
    }
    [self.searchDelegate receivedSearchResults:searchResults forSource:self.tag];
}

#pragma mark -

- (void)dealloc
{
    [self.request cancel];
    self.request = nil;
    
	[super dealloc];
}

@end

