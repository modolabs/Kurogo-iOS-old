#import "PeopleModule.h"
#import "MITModuleURL.h"
#import "PeopleSearchViewController.h"
#import "PeopleDetailsViewController.h"
#import "PeopleRecentsData.h"
#import "PersonDetails.h"
#import "ModoSearchBar.h"

static NSString * const PeopleStateSearchBegin = @"search-begin";
static NSString * const PeopleStateSearchComplete = @"search-complete";
static NSString * const PeopleStateSearchExternal = @"search";
static NSString * const PeopleStateDetail = @"detail";

@implementation PeopleModule

@synthesize viewController, request;

- (id)init
{
    if (self = [super init]) {
        self.tag = DirectoryTag;
        self.shortName = @"People";
        self.longName = @"People";
        self.iconName = @"people";
        self.supportsFederatedSearch = YES;

		self.viewController = [[[PeopleSearchViewController alloc] init] autorelease];
		self.viewController.navigationItem.title = self.longName;
        
        self.viewControllers = [NSArray arrayWithObject:viewController];
    }
    return self;
}

- (void)applicationWillTerminate
{
	MITModuleURL *url = [[MITModuleURL alloc] initWithTag:DirectoryTag];
	
	UIViewController *visibleVC = self.viewController.navigationController.visibleViewController;
	if ([visibleVC isMemberOfClass:[PeopleSearchViewController class]]) {
		PeopleSearchViewController *searchVC = (PeopleSearchViewController *)visibleVC;
		//if (searchVC.searchController.active) {
        if ([searchVC.searchController isActive]) {
			if (searchVC.searchResults != nil) {
				[url setPath:PeopleStateSearchComplete query:searchVC.searchTerms];
			} else {
				[url setPath:PeopleStateSearchBegin query:searchVC.searchTerms];
			}
		} else {
			[url setPath:nil query:nil];
		}

	} else if ([visibleVC isMemberOfClass:[PeopleDetailsViewController class]]) {
		PeopleDetailsViewController *detailVC = (PeopleDetailsViewController *)visibleVC;
		[url setPath:PeopleStateDetail query:detailVC.personDetails.uid];
	}
	
	[url setAsModulePath];
	[url release];
}


/*
- (void)applicationDidFinishLaunching
{
}
*/

- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query {
    BOOL didHandle = NO;
	
    if ([localPath isEqualToString:LocalPathFederatedSearch]) {
        // fedsearch?query
        self.selectedResult = nil;
        self.viewController.view;
        [self.viewController.searchController setActive:NO animated:NO];
        [self.viewController presentSearchResults:self.searchResults];
        self.viewController.searchBar.text = query;
        [self resetNavStack];
        didHandle = YES;

        // TODO: remove this line when state restoration is merged
        return didHandle;
        
    } else if ([localPath isEqualToString:LocalPathFederatedSearchResult]) {
        // fedresult?rownum
        NSInteger row = [query integerValue];
        PeopleDetailsViewController *detailVC = [[[PeopleDetailsViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
        self.selectedResult = [self.searchResults objectAtIndex:row];
        detailVC.personDetails = [PersonDetails retrieveOrCreate:self.selectedResult];
        self.viewControllers = [NSArray arrayWithObject:detailVC];
        didHandle = YES;
        
        // TODO: remove this line when state restoration is merged
        return didHandle;
    }
    
	[self resetNavStack];
 
	if (localPath == nil) {
		didHandle = YES;
	} 
	
	// search
	else if ([localPath isEqualToString:PeopleStateSearchBegin]) {
		self.viewController.view;
		if (query != nil) {
			self.viewController.searchBar.text = query;
		}
		//viewController.actionAfterAppearing = @selector(prepSearchBar);
        didHandle = YES;
		
	} else if (!query || [query length] == 0) {
		// from this point forward we don't want to handle anything
		// without proper query terms
		didHandle = NO;
		
	} else if ([localPath isEqualToString:PeopleStateSearchComplete]) {
		self.viewController.view;
		//viewController.actionAfterAppearing = @selector(prepSearchBar);
        [self.viewController beginExternalSearch:query];
		didHandle = YES;
		
	} else if ([localPath isEqualToString:PeopleStateSearchExternal]) {
		// this path is reserved for calling from other modules
		// do not save state with this path       
		self.viewController.view;
        [self.viewController.searchController setActive:NO animated:NO];
        [self.viewController beginExternalSearch:query];
        [self becomeActiveTab];
        didHandle = YES;
    
	}

	// detail
	else if ([localPath isEqualToString:PeopleStateDetail]) {
		PersonDetails *person = [PeopleRecentsData personWithUID:query];
		if (person != nil) {
			PeopleDetailsViewController *detailVC = [[PeopleDetailsViewController alloc] initWithStyle:UITableViewStyleGrouped];
			detailVC.personDetails = person;
			[viewController.navigationController pushViewController:detailVC animated:NO];
			[detailVC release];
			didHandle = YES;
		}
	}
	
    return didHandle;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)resetNavStack {
    self.viewControllers = [NSArray arrayWithObject:viewController];
}

- (NSString *)titleForSearchResult:(id)result {
    NSString *fullname = nil;
    if (result && [result isKindOfClass:[NSDictionary class]]) {
        NSDictionary *person = (NSDictionary *)result;
        NSArray *namesFromJSON = [person objectForKey:@"cn"];
        if ([namesFromJSON count] > 0) {
            fullname = [namesFromJSON objectAtIndex:0];
        }
    }
    return fullname;
}

- (NSString *)subtitleForSearchResult:(id)result {
    NSString *title = nil;
    if (result && [result isKindOfClass:[NSDictionary class]]) {
        NSDictionary *person = (NSDictionary *)result;
        NSArray *detailAttributeArray = [person objectForKey:@"title"];
        if ([detailAttributeArray count] > 0) {
            title = [detailAttributeArray objectAtIndex:0];
        }
    }
    return title;
}

- (void)performSearchForString:(NSString *)searchText {
    [super performSearchForString:searchText];
    
    self.request = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    // TODO: handle failure to make request
    [self.request requestObjectFromModule:@"people"
                                  command:@"search"
                               parameters:[NSDictionary dictionaryWithObjectsAndKeys:searchText, @"q", nil]];
}

- (void)abortSearch {
    if (self.request) {
        [self.request abortRequest];
        self.request = nil;
    }
    [super abortSearch];
}

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result {
    self.request = nil;

	if ([result isKindOfClass:[NSArray class]]) {
		self.searchResults = result;
    } else {
        self.request = nil;
        self.searchResults = nil;
        self.searchProgress = 1.0;
    }
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error {
    self.request = nil;
    self.searchResults = nil;
    self.searchProgress = 1.0;
}

@end

