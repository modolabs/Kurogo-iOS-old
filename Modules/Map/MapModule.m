#import "MapModule.h"
#import "MapDetailViewController.h"
#import "KGOPlacemark.h"
#import "MapHomeViewController.h"
#import "KGOCategoryListViewController.h"
#import "CoreDataManager.h"
#import "KGOMapCategory.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "Foundation+KGOAdditions.h"

NSString * const MapTypePreference = @"MapType";
NSString * const MapTypePreferenceChanged = @"MapTypeChanged";

@implementation MapModule
@synthesize request = _request;

- (void)dealloc
{	
	[super dealloc];
}

- (void)launch {
#ifdef DEBUG
    NSLog(@"deleting map categories");
    for (NSManagedObject *aCategory in [[CoreDataManager sharedManager] objectsForEntity:MapCategoryEntityName matchingPredicate:nil]) {
        [[CoreDataManager sharedManager] deleteObject:aCategory];
        [[CoreDataManager sharedManager] saveData];
    }
#endif
}


#pragma mark Search

- (BOOL)supportsFederatedSearch {
    return YES;
}

- (void)performSearchWithText:(NSString *)searchText params:(NSDictionary *)params delegate:(id<KGOSearchDelegate>)delegate {
    self.searchDelegate = delegate;

    if (!params) {
        params = [NSDictionary dictionaryWithObjectsAndKeys:searchText, @"q", nil];
    }
    
    self.request = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                   module:MapTag
                                                                     path:@"search"
                                                                   params:params];
    self.request.expectedResponseType = [NSDictionary class];
    if (self.request)
        [self.request connect];
}


#pragma mark Data

- (NSArray *)objectModelNames {
    return [NSArray arrayWithObject:@"MapModel"];
}


#pragma mark Navigation

- (NSArray *)registeredPageNames {
    return [NSArray arrayWithObjects:
            LocalPathPageNameHome, LocalPathPageNameSearch, LocalPathPageNameDetail,
            LocalPathPageNameCategoryList, LocalPathPageNameItemList, nil];
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            vc = [[[MapHomeViewController alloc] initWithNibName:@"MapHomeViewController" bundle:nil] autorelease];
        } else {
            vc = [[[MapHomeViewController alloc] initWithNibName:@"MapHomeViewController-iPad" bundle:nil] autorelease];
        }
        
    } else if ([pageName isEqualToString:LocalPathPageNameSearch]) {
        vc = [[[MapHomeViewController alloc] init] autorelease];
        
        NSString *searchText = [params objectForKey:@"q"];
        if (searchText) {
            [(MapHomeViewController *)vc setSearchTerms:searchText];
        }
        
        NSString *identifier = [params objectForKey:@"identifier"];
        if (identifier) {
            [(MapHomeViewController *)vc setSearchTerms:identifier];
        }
        
    } else if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        vc = [[[MapDetailViewController alloc] init] autorelease];
        MapDetailViewController *detailVC = (MapDetailViewController *)vc;

        KGOPlacemark *place = [params objectForKey:@"place"];
        if (place) {
            detailVC.placemark = place;
        }
        id<KGODetailPagerController> controller = [params objectForKey:@"pagerController"];
        if (controller) {
            KGODetailPager *pager = [[[KGODetailPager alloc] initWithPagerController:controller delegate:detailVC] autorelease];
            detailVC.pager = pager;
        }
        
    } else if ([pageName isEqualToString:LocalPathPageNameCategoryList]) {
		NSArray *categories = [params objectForKey:@"categories"];
		if (categories) {
			vc = [[[KGOCategoryListViewController alloc] init] autorelease];
            KGOCategoryListViewController *categoryVC = (KGOCategoryListViewController *)vc;
            categoryVC.categoryEntityName = MapCategoryEntityName;
            categoryVC.categories = categories;
            
            KGOMapCategory *parentCategory = [params objectForKey:@"parentCategory"];
            if ([parentCategory isKindOfClass:[KGOMapCategory class]]) {
                categoryVC.parentCategory = parentCategory;
            }
		}
        
    }
    return vc;
}

- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query {
    if ([localPath isEqualToString:LocalPathPageNameSearch]) {
        NSDictionary *params = [NSURL parametersFromQueryString:query];
        NSString *searchText = [params objectForKey:@"q"];
        if (searchText) {
            return [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameSearch forModuleTag:MapTag params:params];
        }
        
        NSString *placemarkID = [params objectForKey:@"identifier"];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier like %@", placemarkID];
        KGOPlacemark *placemark = [[[CoreDataManager sharedManager] objectsForEntity:KGOPlacemarkEntityName
                                                                   matchingPredicate:pred] lastObject];
        if (placemark) {
            KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
            UIViewController *visibleVC = [appDelegate visibleViewController];
            // this will be true if we invoked browse categories from the map module
            if (![visibleVC isKindOfClass:[MapHomeViewController class]]) {
                [appDelegate showPage:LocalPathPageNameHome forModuleTag:MapTag params:nil];
            }
            // otherwise we picked an annotation from another module
            visibleVC = [appDelegate visibleViewController];
            if (![visibleVC isKindOfClass:[MapHomeViewController class]]) {
                return NO;
            }
            // this will dismiss browse categories list, otherwise it does nothing
            [appDelegate dismissAppModalViewControllerAnimated:YES];
            [(MapHomeViewController *)visibleVC setAnnotations:[NSArray arrayWithObject:placemark]];
            return YES;
            
        }
        
    }
    return NO;
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
        KGOPlacemark *placemark = [KGOPlacemark placemarkWithDictionary:aResult];
        if (placemark)
            [searchResults addObject:placemark];
    }
    NSLog(@"%@", searchResults);
    [self.searchDelegate searcher:self didReceiveResults:searchResults];
}

@end
