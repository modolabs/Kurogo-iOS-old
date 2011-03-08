#import "MapModule.h"
#import "MapDetailViewController.h"
#import "MapSearchResultAnnotation.h"
#import "KGOPlacemark.h"
#import "MapBookmarkManager.h"
#import "TileServerManager.h"
#import "CalendarModel.h"
#import "MapHomeViewController.h"
#import "KGOCategoryListViewController.h"
#import "CoreDataManager.h"
#import "KGOMapCategory.h"

NSString * const MapTypePreference = @"MapType";
NSString * const MapTypePreferenceChanged = @"MapTypeChanged";

@implementation MapModule
@synthesize request = _request;

- (void)dealloc
{	
	[super dealloc];
}
/*
- (void)applicationDidFinishLaunching
{
    // force TileServerManager to load so we can get projection info asap
    [TileServerManager isInitialized];
}
*/


- (void)launch {
#ifdef USE_MOBILE_DEV
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
    
    self.request = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                   module:MapTag
                                                                     path:@"search"
                                                                   params:[NSDictionary dictionaryWithObjectsAndKeys:searchText, @"q", nil]];
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
        vc = [[[MapHomeViewController alloc] init] autorelease];
        
    } else if ([pageName isEqualToString:LocalPathPageNameSearch]) {
        vc = [[[MapHomeViewController alloc] init] autorelease];
        
        NSString *searchText = [params objectForKey:@"q"];
        if (searchText) {
            [(MapHomeViewController *)vc setSearchTerms:searchText];
        }
        
    } else if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        vc = [[[MapDetailViewController alloc] init] autorelease];
        MapDetailViewController *detailVC = (MapDetailViewController *)vc;

        KGOPlacemark *place = [params objectForKey:@"place"];
        if (place) {
            detailVC.placemark = place;
        }
        KGOSearchDisplayController *controller = [params objectForKey:@"searchController"];
        if (controller) {
            KGODetailPager *pager = [[[KGODetailPager alloc] initWithPagerController:controller delegate:detailVC] autorelease];
            detailVC.pager = pager;
        }
        
    } else if ([pageName isEqualToString:LocalPathPageNameCategoryList]) {
		NSArray *categories = [params objectForKey:@"categories"];
		if (categories) {
			vc = [[[KGOCategoryListViewController alloc] init] autorelease];
            KGOCategoryListViewController *categoryVC = (KGOCategoryListViewController *)vc;
            categoryVC.entityName = MapCategoryEntityName;
            categoryVC.categories = categories;
            
            KGOMapCategory *parentCategory = [params objectForKey:@"parentCategory"];
            if ([parentCategory isKindOfClass:[KGOMapCategory class]]) {
                categoryVC.parentCategory = parentCategory;
            }
		}
        
    } else if ([pageName isEqualToString:LocalPathPageNameItemList]) {
        
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
        KGOPlacemark *placemark = [[KGOPlacemark placemarkWithDictionary:aResult] autorelease];
        if (placemark)
            [searchResults addObject:placemark];
    }
    NSLog(@"%@", searchResults);
    [self.searchDelegate searcher:self didReceiveResults:searchResults];
}

@end
