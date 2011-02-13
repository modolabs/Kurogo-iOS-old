#import "MapModule.h"
#import "MITMapDetailViewController.h"
#import "MapSearchResultAnnotation.h"
#import "KGOPlacemark.h"
#import "MapBookmarkManager.h"
#import "TileServerManager.h"
#import "CalendarModel.h"
#import "MapHomeViewController.h"
#import "KGOCategoryListViewController.h"

@implementation MapModule
@synthesize request = _request;

- (void)dealloc
{	
	[super dealloc];
}

- (void)applicationDidFinishLaunching
{
    // force TileServerManager to load so we can get projection info asap
    [TileServerManager isInitialized];
}

#pragma mark Search

- (BOOL)supportsFederatedSearch {
    return YES;
}

- (void)performSearchWithText:(NSString *)searchText params:(NSDictionary *)params delegate:(id<KGOSearchDelegate>)delegate {
    _searchDelegate = delegate;
    
    self.request = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    [self.request requestObjectFromModule:@"map"
                                  command:@"search"
                               parameters:[NSDictionary dictionaryWithObjectsAndKeys:searchText, @"q", nil]];
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

- (UIViewController *)moduleHomeScreenWithParams:(NSDictionary *)args {
    MapHomeViewController *vc = [[[MapHomeViewController alloc] init] autorelease];
    return vc;
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [self moduleHomeScreenWithParams:params];
        
    } else if ([pageName isEqualToString:LocalPathPageNameSearch]) {
        vc = [self moduleHomeScreenWithParams:params];
        
        NSString *searchText = [params objectForKey:@"q"];
        if (searchText) {
            [(MapHomeViewController *)vc setSearchTerms:searchText];
        }
        
    } else if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        KGOEvent *event = [params objectForKey:@"event"];
        if (event) {
            vc = [[[MITMapDetailViewController alloc] init] autorelease];
        }
        
    } else if ([pageName isEqualToString:LocalPathPageNameCategoryList]) {
		NSArray *categories = [params objectForKey:@"categories"];
		if (categories) {
			vc = [[[KGOCategoryListViewController alloc] init] autorelease];
			[(KGOCategoryListViewController *)vc setCategories:categories];
		}
        
    } else if ([pageName isEqualToString:LocalPathPageNameItemList]) {
        
    }
    return vc;
}



#pragma mark JSONAPIDelegate

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)JSONObject
{	
    self.request = nil;
    if (JSONObject && [JSONObject isKindOfClass:[NSDictionary class]]) {
        NSArray *results = [JSONObject objectForKey:@"results"];
        NSMutableArray *annotations = [NSMutableArray arrayWithCapacity:[results count]];
        for (NSDictionary *info in results) {
            ArcGISMapAnnotation *annotation = [[[ArcGISMapAnnotation alloc] initWithInfo:info] autorelease];
            [annotations addObject:annotation];
        }
        [_searchDelegate searcher:self didReceiveResults:annotations];
	}
}

- (void)request:(JSONAPIRequest *)request madeProgress:(CGFloat)progress {

}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error {
    self.request = nil;
}

/*
#pragma mark Search and state

NSString * const MapsLocalPathDetail = @"detail";
NSString * const MapsLocalPathList = @"list";

- (void)resetNavStack {
    self.viewControllers = [NSArray arrayWithObject:self.campusMapVC];
}

- (void)performSearchForString:(NSString *)searchText {
    if (![TileServerManager isInitialized]) {
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(tileServerDidSetup) 
                                                     name:kTileServerManagerProjectionIsReady
                                                   object:nil];
    }
    
    [super performSearchForString:searchText];
    
    self.request = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    [self.request requestObjectFromModule:@"map"
                                  command:@"search"
                               parameters:[NSDictionary dictionaryWithObjectsAndKeys:searchText, @"q", nil]];
}

- (void)tileServerDidSetup {
    for (ArcGISMapAnnotation *annotation in self.searchResults) {
        [annotation updateWithInfo:annotation.info];
    }
}

- (void)abortSearch {
    if (self.request) {
        [self.request abortRequest];
        self.request = nil;
    }
    [super abortSearch];
}

- (NSString *)titleForSearchResult:(id)result {
    ArcGISMapAnnotation *annotation = (ArcGISMapAnnotation *)result;
    return annotation.name;
}

- (NSString *)subtitleForSearchResult:(id)result {
    ArcGISMapAnnotation *annotation = (ArcGISMapAnnotation *)result;
    return annotation.street;
}

- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query
{
    BOOL didHandle = NO;
    
    if ([localPath isEqualToString:LocalPathFederatedSearch]) {
        // fedsearch?query
        self.selectedResult = nil;
        self.campusMapVC.view;
        self.campusMapVC.searchResults = self.searchResults;
        self.campusMapVC.searchBar.text = query;
        self.campusMapVC.lastSearchText = query;
        [self.campusMapVC.searchController setActive:NO animated:NO];
        [self resetNavStack];
        didHandle = YES;
        
    } else if ([localPath isEqualToString:LocalPathFederatedSearchResult]) {
        // fedresult?rownum
        NSInteger row = [query integerValue];
        
        MITMapDetailViewController *detailVC = [[[MITMapDetailViewController alloc] init] autorelease];
        self.selectedResult = [self.searchResults objectAtIndex:row];
        detailVC.annotation = self.selectedResult;
        self.viewControllers = [NSArray arrayWithObject:detailVC];
        
        didHandle = YES;
        
    } else if ([localPath isEqualToString:LocalPathMapsSelectedAnnotation]) {
        // annotation?uniqueID
        MapSavedAnnotation *saved = [[MapBookmarkManager defaultManager] savedAnnotationForID:query];
        if (saved) {
            NSDictionary *info = [NSKeyedUnarchiver unarchiveObjectWithData:saved.info];
            ArcGISMapAnnotation *annotation = [[[ArcGISMapAnnotation alloc] initWithInfo:info] autorelease];
            if (!annotation.dataPopulated) {
                // TODO: issue an identify API request instead of showing a useless annotation
                annotation.coordinate = CLLocationCoordinate2DMake([saved.latitude floatValue], [saved.longitude floatValue]);
                annotation.name = saved.name;
            }
            self.campusMapVC.view; // make sure mapview is loaded
            self.campusMapVC.searchBar.text = saved.name;
            self.campusMapVC.lastSearchText = saved.name;
            [self.campusMapVC.searchController setActive:NO animated:NO];
            NSArray *annotations = [NSArray arrayWithObject:annotation];
            self.campusMapVC.searchResults = annotations;
            [self resetNavStack];

            didHandle = YES;
        }
    } else if ([localPath isEqualToString:@"search"]) {

        NSArray *queryParts = [query componentsSeparatedByString:@"&"];
        NSDictionary *params = nil;
        if ([queryParts count] > 1) {
            NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithCapacity:[queryParts count] - 1];
            for (NSString *queryPart in queryParts) {
                NSArray *args = [queryPart componentsSeparatedByString:@"="];
                switch ([args count]) {
                    case 1:
                        query = queryPart;
                        break;
                    case 2:
                        [mutableParams setObject:[args objectAtIndex:1] forKey:[args objectAtIndex:0]];
                        break;
                    default:
                        break;
                }
            }
            params = [NSDictionary dictionaryWithDictionary:mutableParams];
        }
        
        [self resetNavStack];
        self.campusMapVC.view;
	            
        // populate search bar
        self.campusMapVC.searchBar.text = query;
        self.campusMapVC.lastSearchText = query;
        [self.campusMapVC.searchController setActive:NO animated:NO];
        self.campusMapVC.hasSearchResults = YES;
            
        // perform the search from the network
        [self.campusMapVC search:query params:params];
        didHandle = YES;

    }

    if (didHandle) {
        [self becomeActiveTab];
    }
        
	return didHandle;
}
*/
@end
