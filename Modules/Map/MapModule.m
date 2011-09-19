#import "MapModule.h"
#import "MapDetailViewController.h"
#import "KGOPlacemark.h"
#import "MapHomeViewController.h"
#import "MapCategoryListViewController.h"
#import "CoreDataManager.h"
#import "KGOMapCategory.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "Foundation+KGOAdditions.h"
#import "KGOSidebarFrameViewController.h"

NSString * const MapTypePreference = @"MapType";
NSString * const MapTypePreferenceChanged = @"MapTypeChanged";

@implementation MapModule

//@synthesize request = _request;
@synthesize dataManager;

- (void)dealloc
{	
    self.dataManager = nil;
    
	[super dealloc];
}

- (void)willLaunch {
#ifdef DEBUG
    /*
    if (![self isActive]) {
        NSLog(@"deleting map categories");
        for (NSManagedObject *aCategory in [[CoreDataManager sharedManager] objectsForEntity:MapCategoryEntityName
                                                                           matchingPredicate:nil]
        ) {
            [[CoreDataManager sharedManager] deleteObject:aCategory];
        }
        [[CoreDataManager sharedManager] saveData];
    }
     */
#endif
    [super willLaunch];
    
    if (!self.dataManager) {
        self.dataManager = [[[MapDataManager alloc] init] autorelease];
        self.dataManager.moduleTag = self.tag;
    }
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
    
    self.dataManager.searchDelegate = delegate;
    [self.dataManager search:searchText];
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
            DLog(@"annotations: %@", annotations);
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

            KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
            
            UIViewController *topVC = [appDelegate visibleViewController];
            if (topVC.modalViewController) {
                [topVC dismissModalViewControllerAnimated:YES];
            }
            
            KGONavigationStyle navStyle = [appDelegate navigationStyle];
            if (navStyle == KGONavigationStyleTabletSidebar) {
                KGOSidebarFrameViewController *homescreen = (KGOSidebarFrameViewController *)[appDelegate homescreen];
                topVC = homescreen.visibleViewController;
            }
            
            if ([topVC isKindOfClass:[MapHomeViewController class]]) {
                MapHomeViewController *mapVC = (MapHomeViewController *)topVC;
                [mapVC setAnnotations:annotations];
                if (mapVC.selectedPopover) {
                    [mapVC dismissPopoverAnimated:YES];
                    return nil;
                }
                
            } else {
                return [self modulePage:LocalPathPageNameHome params:params];
            }
        }
        
    } else if ([pageName isEqualToString:LocalPathPageNameCategoryList]) {
        
        MapCategoryListViewController *categoryVC = [[[MapCategoryListViewController alloc] init] autorelease];
        categoryVC.dataManager = self.dataManager;
        categoryVC.categoryEntityName = MapCategoryEntityName;

        KGOMapCategory *parentCategory = [params objectForKey:@"parentCategory"];
        if ([parentCategory isKindOfClass:[KGOMapCategory class]]) {
            categoryVC.parentCategory = parentCategory;
        }
        
        NSArray *listItems = [params objectForKey:@"listItems"];
        if (listItems) {
            categoryVC.listItems = listItems;
        }
        
        KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
        UIViewController *topVC = [appDelegate visibleViewController];

        KGONavigationStyle navStyle = [appDelegate navigationStyle];
        if (navStyle == KGONavigationStyleTabletSidebar) {
            KGOSidebarFrameViewController *homescreen = (KGOSidebarFrameViewController *)[appDelegate homescreen];
            topVC = homescreen.visibleViewController;
        }
        
        if ([topVC isKindOfClass:[MapHomeViewController class]]) {
            MapHomeViewController *mapVC = (MapHomeViewController *)topVC;
            if (mapVC.selectedPopover) {
                mapVC.selectedPopover.contentViewController = categoryVC;
                return nil;
            }
            
        } else {
            return [self modulePage:LocalPathPageNameHome params:params];
        }
        
        vc = categoryVC;
    }
    return vc;
}

- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query {
    if ([localPath isEqualToString:LocalPathPageNameSearch]) {
        NSDictionary *params = [NSURL parametersFromQueryString:query];
        NSString *searchText = [params objectForKey:@"q"];
        if (searchText) {
            return [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameSearch forModuleTag:self.tag params:params];
        }
        
        NSString *placemarkID = [params objectForKey:@"identifier"];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier like %@", placemarkID];
        KGOPlacemark *placemark = [[[CoreDataManager sharedManager] objectsForEntity:KGOPlacemarkEntityName
                                                                   matchingPredicate:pred] lastObject];
        if (placemark) {
            placemark.moduleTag = self.tag;
            
            KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
            UIViewController *visibleVC = [appDelegate visibleViewController];
            // this will be true if we invoked browse categories from the map module
            if (![visibleVC isKindOfClass:[MapHomeViewController class]]) {
                [appDelegate showPage:LocalPathPageNameHome forModuleTag:self.tag params:nil];
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

@end
