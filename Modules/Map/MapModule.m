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
/*
- (void)launch {
#ifdef DEBUG
    if (![self isActive]) {
        NSLog(@"deleting map categories");
        for (NSManagedObject *aCategory in [[CoreDataManager sharedManager] objectsForEntity:MapCategoryEntityName
                                                                           matchingPredicate:nil]
        ) {
            [[CoreDataManager sharedManager] deleteObject:aCategory];
        }
        [[CoreDataManager sharedManager] saveData];
    }
#endif
    [super launch];
}
*/
- (NSArray *)userDefaults
{
    return [NSArray arrayWithObjects:MapTypePreference, nil];
}


#pragma mark Search

- (BOOL)supportsFederatedSearch {
    return YES;
}

- (void)performSearchWithText:(NSString *)searchText params:(NSDictionary *)params delegate:(id<KGOSearchResultsHolder>)delegate {
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
    if ([pageName isEqualToString:LocalPathPageNameHome] || [pageName isEqualToString:LocalPathPageNameSearch]) {
        MapHomeViewController *mapVC;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            mapVC = [[[MapHomeViewController alloc] initWithNibName:@"MapHomeViewController" bundle:nil] autorelease];
        } else {
            if ([[NSBundle mainBundle] pathForResource:@"MapHomeViewController-iPad" ofType:@"nib"] != nil) {
                mapVC = [[[MapHomeViewController alloc] initWithNibName:@"MapHomeViewController-iPad" bundle:nil] autorelease];
            } else {
                mapVC = [[[MapHomeViewController alloc] initWithNibName:@"MapHomeViewController" bundle:nil] autorelease];
            }
        }
        
        mapVC.mapModule = self;
        
        NSString *searchText = [params objectForKey:@"q"];
        if (searchText) {
            mapVC.searchTerms = searchText;
            mapVC.searchOnLoad = YES;
            mapVC.searchParams = params;
        }

        NSArray *annotations = [params objectForKey:@"annotations"];
        if (annotations) {
            NSLog(@"annotations: %@", annotations);
            mapVC.annotations = annotations;
        }
        
        vc = mapVC;
        
    } else if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        KGOPlacemark *place = [params objectForKey:@"place"];
        if (place) {
            MapDetailViewController *detailVC = [[[MapDetailViewController alloc] init] autorelease];
            id<KGODetailPagerController> controller = [params objectForKey:@"pagerController"];
            if (controller) {
                KGODetailPager *pager = [[[KGODetailPager alloc] initWithPagerController:controller delegate:detailVC] autorelease];
                detailVC.pager = pager;
            }
            detailVC.placemark = place;
            
            vc = detailVC;
        }
        
        KGOPlacemark *detailItem = [params objectForKey:@"detailItem"];
        if (detailItem) {
            NSArray *annotations = [NSArray arrayWithObject:detailItem];
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:annotations, @"annotations", nil];

            UIViewController *topVC = [KGO_SHARED_APP_DELEGATE() visibleViewController];
            if (topVC.modalViewController) {
                [topVC dismissModalViewControllerAnimated:YES];
            }
            
            if ([topVC isKindOfClass:[MapHomeViewController class]]) {
                [(MapHomeViewController *)topVC setAnnotations:annotations];
                
            } else {
                return [self modulePage:LocalPathPageNameHome params:params];
            }
        }
        
    } else if ([pageName isEqualToString:LocalPathPageNameCategoryList]) {
        
        KGOCategoryListViewController *categoryVC = [[[KGOCategoryListViewController alloc] init] autorelease];
        categoryVC.categoryEntityName = MapCategoryEntityName;

        KGOMapCategory *parentCategory = [params objectForKey:@"parentCategory"];
        if ([parentCategory isKindOfClass:[KGOMapCategory class]]) {
            categoryVC.parentCategory = parentCategory;
        }
        
		NSArray *categories = [params objectForKey:@"categories"];
        NSArray *items = [params objectForKey:@"items"];
        BOOL hasSubcategories = [parentCategory.hasSubcategories boolValue];
        
        if (parentCategory && hasSubcategories && !items.count) {
            categoryVC.categoriesRequest = [self subcategoriesRequestForCategory:parentCategory.identifier delegate:categoryVC];
        
        } else if (parentCategory && !categories.count && !items.count) {
            // TODO: communicate this delimiter better between server & client
            NSString *categoryPath = [parentCategory.identifier stringByReplacingOccurrencesOfString:@"/" withString:@":"];
            NSDictionary *params = [NSDictionary dictionaryWithObject:categoryPath
                                                               forKey:@"category"];
            categoryVC.leafItemsRequest = [[KGORequestManager sharedManager] requestWithDelegate:categoryVC
                                                                                          module:self.tag
                                                                                            path:@"places"
                                                                                          params:params];
            
            JSONObjectHandler createMapItems = [[^(id jsonObj) {
                NSArray *results = [jsonObj arrayForKey:@"results"];
                __block NSInteger count = 0;
                [results enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    KGOPlacemark *placemark = [KGOPlacemark placemarkWithDictionary:obj];
                    if (placemark) {
                        count++;
                    }
                }];
                
                return count;
                
            } copy] autorelease];
            
            categoryVC.leafItemsRequest.handler = createMapItems;
            
        } else if (categories) {
            categoryVC.categories = categories;
            
		} else if (items) {
            categoryVC.leafItems = items;
            
        }
        
        vc = categoryVC;
    }
    return vc;
}

- (KGORequest *)subcategoriesRequestForCategory:(NSString *)category delegate:(id<KGORequestDelegate>)delegate
{
    NSDictionary *params = nil;
    
    if (category) {
        params = [NSDictionary dictionaryWithObject:category forKey:@"category"];
    }
    
    KGORequest *categoriesRequest = [[KGORequestManager sharedManager] requestWithDelegate:delegate
                                                                                    module:self.tag
                                                                                      path:@"categories"
                                                                                    params:params];
    categoriesRequest.expectedResponseType = [NSArray class];
    
    __block JSONObjectHandler createMapCategories;
    __block NSUInteger sortOrder = 0;
    __block CoreDataManager *coreDataManager = [CoreDataManager sharedManager];
    createMapCategories = [[^(id jsonObj) {
        NSInteger categoriesCreated = 0;
        NSArray *jsonArray = (NSArray *)jsonObj;
        for (id categoryObj in jsonArray) {
            if ([categoryObj isKindOfClass:[NSDictionary class]]) {
                NSDictionary *categoryDict = (NSDictionary *)categoryObj;
                NSArray *categoryPath = nil;
                id identifier = [categoryDict objectForKey:@"id"];
                if ([identifier isKindOfClass:[NSArray class]]) {
                    categoryPath = identifier;
                } else if ([identifier isKindOfClass:[NSNumber class]] || [identifier isKindOfClass:[NSString class]]) {
                    categoryPath = [NSArray arrayWithObject:identifier];
                }
                if (categoryPath) {
                    KGOMapCategory *category = [KGOMapCategory categoryWithPath:categoryPath];
                    NSString *title = [categoryDict stringForKey:@"title" nilIfEmpty:YES];
                    if (title && ![category.title isEqualToString:title]) {
                        category.title = title;
                        category.sortOrder = [NSNumber numberWithInt:sortOrder];
                        sortOrder++; // this can be anything so long as it's ascending within the parent category
                    }
                    if (![category.browsable boolValue]) {
                        category.browsable = [NSNumber numberWithBool:YES];
                    }
                    categoriesCreated++;
                    
                    NSArray *subcategories = [categoryDict arrayForKey:@"subcategories"];
                    // TODO: make the API return whether or not there are pending subcategories
                    // this is going to break when we do that
                    if (subcategories.count) {
                        categoriesCreated += createMapCategories(subcategories);
                        category.hasSubcategories = [NSNumber numberWithBool:YES];
                    }
                }
            }
        }
        
        [coreDataManager saveDataWithTemporaryMergePolicy:NSOverwriteMergePolicy];
        
        return categoriesCreated;
    } copy] autorelease];
    
    categoriesRequest.handler = createMapCategories;
    
    return categoriesRequest;
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
            [visibleVC dismissModalViewControllerAnimated:YES];
            [(MapHomeViewController *)visibleVC setAnnotations:[NSArray arrayWithObject:placemark]];
            return YES;
            
        }
        
    }
    return NO;
}

#pragma mark KGORequestDelegate

- (void)requestWillTerminate:(KGORequest *)request {
    if (request == self.request) {
        self.request = nil;
    }
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result {
    if (request == self.request) {
        self.request = nil;
        
        NSArray *resultArray = [result arrayForKey:@"results"];
        NSMutableArray *searchResults = [NSMutableArray arrayWithCapacity:[(NSArray *)resultArray count]];
        for (id aResult in resultArray) {
            KGOPlacemark *placemark = [KGOPlacemark placemarkWithDictionary:aResult];
            if (placemark)
                [searchResults addObject:placemark];
        }
        DLog(@"%@", searchResults);
        [self.searchDelegate searcher:self didReceiveResults:searchResults];
    }
}

@end
