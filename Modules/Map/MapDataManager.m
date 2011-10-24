#import "MapDataManager.h"
#import "KGOPlacemark.h"
#import "CoreDataManager.h"
#import "Foundation+KGOAdditions.h"
#import "KGOMapCategory.h"

@interface MapDataManager (Private)

- (NSArray *)childrenForCategory:(NSString *)categoryID;

@end


@implementation MapDataManager

@synthesize moduleTag;
@synthesize delegate;
@synthesize searchDelegate;

- (void)requestBrowseIndex
{
    if (_indexRequest) {
        return;
    }
    
    _indexRequest = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                    module:self.moduleTag
                                                                      path:@"index"
                                                                   version:1
                                                                    params:nil];
    [_indexRequest connect];
}

- (void)requestChildrenForCategory:(NSString *)categoryID
{
    if (_categoryRequest) {
        return;
    }
    
    KGOMapCategory *category = [KGOMapCategory categoryWithIdentifier:categoryID];
    KGOMapCategory *parent = category.parentCategory;
    NSMutableArray *references = [NSMutableArray array];
    while (parent) {
        // TODO: make sure this doesn't become an infinite loop
        [references insertObject:parent.identifier atIndex:0];
        parent = parent.parentCategory;
    }
    NSString *categoryReferences = [references componentsJoinedByString:@":"];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            category.identifier, @"category",
                            categoryReferences, @"references",
                            nil];
    
    _categoryRequest = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                       module:self.moduleTag
                                                                         path:@"category"
                                                                      version:1
                                                                       params:params];
    [_categoryRequest connect];
}

- (void)requestDetailsForPlacemark:(KGOPlacemark *)placemark
{
    KGOMapCategory *category = [placemark.categories anyObject];
    KGOMapCategory *parent = category.parentCategory;
    NSMutableArray *references = [NSMutableArray array];
    while (parent && parent.parentCategory != parent) {
        [references addObject:parent.identifier];
        parent = parent.parentCategory;
    }
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            placemark.identifier, @"id",
                            category.identifier, @"category",
                            references, [references componentsJoinedByString:@","],
                            nil];

    [_placemarkForDetailRequest release];
    _placemarkForDetailRequest = [placemark retain];
    _detailRequest = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                     module:self.moduleTag
                                                                       path:@"detail"
                                                                    version:1
                                                                     params:params];
    [_detailRequest connect];
}

- (void)search:(NSString *)searchText
{
    if (_searchRequest) {
        [_searchRequest cancel];
    }
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:searchText, @"q", nil];
    
    _searchRequest = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                     module:self.moduleTag
                                                                       path:@"search"
                                                                    version:1
                                                                     params:params];
    [_searchRequest connect];
}

- (void)searchNearby:(CLLocationCoordinate2D)coordinate
{
    if (_searchRequest) {
        [_searchRequest cancel];
    }
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSString stringWithFormat:@"%.5f", coordinate.latitude], @"lat",
                            [NSString stringWithFormat:@"%.5f", coordinate.longitude], @"lon",
                            nil];
    
    _searchRequest = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                     module:self.moduleTag
                                                                       path:@"search"
                                                                    version:1
                                                                     params:params];
    [_searchRequest connect];
}

#pragma mark KGORequestDelegate

- (void)request:(KGORequest *)request didReceiveResult:(id)result
{
    if (request == _indexRequest || request == _categoryRequest) {
#pragma mark Index/category request response
        NSMutableArray *results = [NSMutableArray array];
        KGOMapCategory *parentCategory = nil;
        NSString *categoryID = [request.getParams objectForKey:@"category"];
        if (categoryID) {
            parentCategory = [KGOMapCategory categoryWithIdentifier:categoryID];
            parentCategory.moduleTag = self.moduleTag;
        }
        
        NSInteger count = 0;
        NSDictionary *dictionary = (NSDictionary *)result;
        NSArray *categories = [dictionary arrayForKey:@"categories"];
        if (categories) {
            for (NSDictionary *categoryData in categories) {
                KGOMapCategory *category = [KGOMapCategory categoryWithDictionary:categoryData];
                if (category) {
                    category.moduleTag = self.moduleTag;
                    category.sortOrder = [NSNumber numberWithInt:count];
                    category.parentCategory = parentCategory;
                    [results addObject:category];
                    count++;
                }
            }
        }
        
        count = 0;
        NSArray *placemarks = [dictionary arrayForKey:@"placemarks"];
        if (placemarks) {
            for (NSDictionary *placemarkData in placemarks) {
                KGOPlacemark *placemark = [KGOPlacemark placemarkWithDictionary:placemarkData];
                if (placemark) {
                    placemark.moduleTag = self.moduleTag;
                    placemark.sortOrder = [NSNumber numberWithInt:count];
                    KGOPlacemark *parent = (KGOPlacemark *)parentCategory;
                    [placemark addCategoriesObject:parent];
                    [results addObject:placemark];
                    count++;
                }
            }
        }
        
        [[CoreDataManager sharedManager] saveData];
        
        if ([self.delegate respondsToSelector:@selector(mapDataManager:didReceiveChildren:forCategory:)]) {
            [self.delegate mapDataManager:self didReceiveChildren:results forCategory:categoryID];
        }
        
    } else if (request == _detailRequest) {
#pragma mark Detail request result
        NSString *title = [result nonemptyStringForKey:@"title"];
        if (title) {
            _placemarkForDetailRequest.title = title;
        }
        NSString *address = [result nonemptyStringForKey:@"address"];
        if (address) {
            _placemarkForDetailRequest.street = address;
        }
        CGFloat lat = [result floatForKey:@"lat"];
        if (lat) {
            _placemarkForDetailRequest.latitude = [NSNumber numberWithFloat:lat];
        }
        CGFloat lon = [result floatForKey:@"lon"];
        if (lon) {
            _placemarkForDetailRequest.longitude = [NSNumber numberWithFloat:lon];
        }
        NSString *geometryType = [result nonemptyStringForKey:@"geometryType"];
        if (geometryType) {
            _placemarkForDetailRequest.geometryType = geometryType;
        }
        id geometry = [result objectForKey:@"geometry"];
        if (geometryType && geometry) {
            if (([geometryType isEqualToString:@"point"]
                 && [geometry isKindOfClass:[NSDictionary class]])
                || (([geometryType isEqualToString:@"polyline"] || [geometryType isEqualToString:@"polygon"])
                    && [geometry isKindOfClass:[NSArray class]]))
            {
                _placemarkForDetailRequest.geometry = [NSKeyedArchiver archivedDataWithRootObject:geometry];
            }
        }
        NSDictionary *details = [result dictionaryForKey:@"details"];
        if (details) {
            NSMutableDictionary *mutableDetails = [NSMutableDictionary dictionaryWithDictionary:details];
            NSString *placemarkDescription = [mutableDetails nonemptyStringForKey:@"description"];
            if (placemarkDescription) {
                _placemarkForDetailRequest.info = placemarkDescription;
                [mutableDetails removeObjectForKey:@"description"];
            }
            if (mutableDetails.count) {
                _placemarkForDetailRequest.userInfo = [NSKeyedArchiver archivedDataWithRootObject:mutableDetails];
            }
        }
        
        if ([self.delegate respondsToSelector:@selector(mapDataManager:didUpdatePlacemark:)]) {
            [self.delegate mapDataManager:self didUpdatePlacemark:_placemarkForDetailRequest];
        }
    
    } else if (request == _searchRequest) {
#pragma mark Search request response
        NSArray *resultArray = [result arrayForKey:@"results"];
        NSMutableArray *searchResults = [NSMutableArray arrayWithCapacity:[(NSArray *)resultArray count]];
        for (id aResult in resultArray) {
            KGOPlacemark *placemark = [KGOPlacemark placemarkWithDictionary:aResult];
            if (placemark) {
                placemark.moduleTag = self.moduleTag;
                [searchResults addObject:placemark];
            }
        }
        DLog(@"%@", searchResults);
        [self.searchDelegate receivedSearchResults:searchResults forSource:self.moduleTag];
    }
}

- (void)requestWillTerminate:(KGORequest *)request
{
    if (request == _indexRequest) {
        _indexRequest = nil;
    } else if (request == _categoryRequest) {
        _categoryRequest = nil;
    } else if (request == _detailRequest) {
        _detailRequest = nil;
        
        [_placemarkForDetailRequest release];
        _placemarkForDetailRequest = nil;
    } else if (request == _searchRequest) {
        _searchRequest = nil;
    } 
}

- (void)request:(KGORequest *)request didFailWithError:(NSError *)error
{
}

- (void)dealloc
{
    [_indexRequest cancel];
    [_categoryRequest cancel];
    [_detailRequest cancel];
    [_searchRequest cancel];
    self.delegate = nil;
    self.searchDelegate = nil;
    self.moduleTag = nil;
    [_placemarkForDetailRequest release];
    [super dealloc];
}

@end
