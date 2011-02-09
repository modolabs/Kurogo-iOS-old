#import "PeopleModule.h"
#import "PeopleSearchViewController.h"
#import "PeopleDetailsViewController.h"
#import "PeopleRecentsData.h"
#import "PersonDetails.h"
#import "KGOSearchDelegate.h"

@implementation PeopleModule

@synthesize request;

#pragma mark Module state

- (void)launch {
    [super launch];
}

- (void)terminate {
    [super terminate];
    
    [[PeopleRecentsData sharedData] clearOldResults];
}

- (void)willBecomeActive {
    [super willBecomeActive];
}

- (void)willBecomeDormant {
    [super willBecomeDormant];
}

- (void)willBecomeVisible {
    [super willBecomeVisible];
}

- (void)willBecomeHidden {
    [super willBecomeHidden];
}

#pragma mark Search

- (BOOL)supportsFederatedSearch {
    return YES;
}

- (void)performSearchWithText:(NSString *)searchText params:(NSDictionary *)params delegate:(id<KGOSearchDelegate>)delegate {
    _searchDelegate = delegate;
    
    self.request = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    [self.request requestObjectFromModule:@"people"
                                  command:@"search"
                               parameters:[NSDictionary dictionaryWithObjectsAndKeys:searchText, @"q", nil]];
}

#pragma mark Data

- (NSArray *)objectModelNames {
    return [NSArray arrayWithObject:@"PeopleDataModel"];
}

#pragma mark Navigation

- (NSArray *)registeredPageNames {
    return [NSArray arrayWithObjects:LocalPathPageNameHome, LocalPathPageNameSearch, LocalPathPageNameDetail, nil];
}

- (UIViewController *)moduleHomeScreenWithParams:(NSDictionary *)args {
    PeopleSearchViewController *peopleVC = [[[PeopleSearchViewController alloc] init] autorelease];
    return peopleVC;
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [self moduleHomeScreenWithParams:params];
    } else if ([pageName isEqualToString:LocalPathPageNameSearch]) {
        vc = [self moduleHomeScreenWithParams:params];

        NSString *searchText = [params objectForKey:@"q"];
        if (searchText) {
            [(PeopleSearchViewController *)vc setSearchTerms:searchText];
        }
        
    } else if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        PersonDetails *person = nil;
        NSString *uid = [params objectForKey:@"uid"];
        if (uid) {
            person = [PeopleRecentsData personWithUID:uid];
        } else {
            person = [params objectForKey:@"personDetails"];
        }
        
        if (person) {
            vc = [[[PeopleDetailsViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
            [(PeopleDetailsViewController *)vc setPersonDetails:person];
        }
    }
    return vc;
}

#pragma mark Application state

- (void)applicationDidFinishLaunching
{
    // force PeopleRecentsData to run -[init], which
    // makes a network request for the LDAP display name mapping
    [PeopleRecentsData sharedData];
}

#pragma mark JSONAPIRequest

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result {
    self.request = nil;

	if ([result isKindOfClass:[NSArray class]]) {
        NSMutableArray *searchResults = [NSMutableArray arrayWithCapacity:[(NSArray *)result count]];
        for (id aResult in result) {
            if ([aResult isKindOfClass:[NSDictionary class]]) {
                PersonDetails *personDetails = [PersonDetails personDetailsWithDictionary:aResult];
                [searchResults addObject:personDetails];
            }
        }
        [_searchDelegate searcher:self didReceiveResults:searchResults];
        
    } else {
        // TODO: handle error or permit default behavior
    }
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error {
    self.request = nil;
    // TODO: handle error or permit default behavior
}

#pragma mark -

- (void)dealloc
{
    self.request.jsonDelegate = nil;
    self.request = nil;
    
	[super dealloc];
}

@end

