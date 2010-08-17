#import "CMModule.h"
#import "CampusMapViewController.h"
#import "MITMapDetailViewController.h"
#import "MapSearchResultAnnotation.h"
#import "MapSavedAnnotation.h"
#import "MapBookmarkManager.h"
#import "TileServerManager.h"

@implementation CMModule
@synthesize campusMapVC = _campusMapVC;
@synthesize request = _request;

- (id)init {
    self = [super init];
    if (self != nil) {
        self.tag = CampusMapTag;
        self.shortName = @"Map";
        self.longName = @"Campus Map";
        self.iconName = @"maps";
        self.supportsFederatedSearch = YES;
       
		self.campusMapVC = [[[CampusMapViewController alloc] init] autorelease];
		self.campusMapVC.title = @"Campus Map";
		self.campusMapVC.campusMapModule = self;
		
        self.viewControllers = [NSArray arrayWithObject:self.campusMapVC];
    }
    return self;
}

- (void)dealloc
{
	self.campusMapVC = nil;
	
	[super dealloc];
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
        self.searchResults = annotations;
	}
}

- (void)request:(JSONAPIRequest *)request madeProgress:(CGFloat)progress {
    self.searchProgress = progress;
}

- (void)handleConnectionFailureForRequest:(JSONAPIRequest *)request {
    self.request = nil;
    self.searchProgress = 1.0;
}

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
        self.campusMapVC.searchResults = self.searchResults;
        self.campusMapVC.lastSearchText = query;
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
            NSArray *annotations = [NSArray arrayWithObject:annotation];
            self.campusMapVC.searchResults = annotations;
            [self resetNavStack];

            didHandle = YES;
        }
    } else if ([localPath isEqualToString:@"search"]) {
        
        [self resetNavStack];
        self.campusMapVC.view;
	            
        // populate search bar
        self.campusMapVC.searchBar.text = query;
        self.campusMapVC.lastSearchText = query;
        self.campusMapVC.hasSearchResults = YES;
            
        // perform the search from the network
        [self.campusMapVC search:query];
        didHandle = YES;

    }

    if (didHandle) {
        [self becomeActiveTab];
    }
        
	return didHandle;
}

@end
