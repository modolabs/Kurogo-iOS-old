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
                                                                       params:params];
    [_categoryRequest connect];
}

- (void)requestDetailsForPlacemark:(NSString *)placemarkID latitude:(CGFloat)lat longitude:(CGFloat)lon
{
}

- (void)search:(NSString *)searchText
{
    if (_searchRequest) {
        [_searchRequest cancel];
    }
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:searchText, @"q", nil];
    
    _searchRequest = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                     module:MapTag
                                                                       path:@"search"
                                                                     params:params];
    [_searchRequest connect];
}

- (void)searchNearby:(CLLocationCoordinate2D)coordinate
{
    if (_searchRequest) {
        [_searchRequest cancel];
    }
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSString stringWithFormat:@"%.45", coordinate.latitude], @"lat",
                            [NSString stringWithFormat:@"%.5f", coordinate.longitude], @"lon",
                            nil];
    
    _searchRequest = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                     module:MapTag
                                                                       path:@"search"
                                                                     params:params];
    [_searchRequest connect];
}

#pragma mark KGORequestDelegate

- (void)request:(KGORequest *)request didReceiveResult:(id)result
{
    if (request == _indexRequest || request == _categoryRequest) {
        NSMutableArray *results = [NSMutableArray array];
        KGOMapCategory *parentCategory = nil;
        NSString *categoryID = [request.getParams objectForKey:@"category"];
        if (categoryID) {
            parentCategory = [KGOMapCategory categoryWithIdentifier:categoryID];
        }
        
        NSInteger count = 0;
        NSDictionary *dictionary = (NSDictionary *)result;
        NSArray *categories = [dictionary arrayForKey:@"categories"];
        if (categories) {
            for (NSDictionary *categoryData in categories) {
                KGOMapCategory *category = [KGOMapCategory categoryWithDictionary:categoryData];
                if (category) {
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
                    placemark.sortOrder = [NSNumber numberWithInt:count];
                    [placemark addCategoriesObject:parentCategory];
                    [results addObject:placemark];
                    count++;
                }
            }
        }
        
        [[CoreDataManager sharedManager] saveData];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(mapDataManager:didReceiveChildren:forCategory:)]) {
            [self.delegate mapDataManager:self didReceiveChildren:results forCategory:categoryID];
        }
        
    } else if (request == _detailRequest) {

    
    } else if (request == _searchRequest) {
        
        NSArray *resultArray = [result arrayForKey:@"results"];
        NSMutableArray *searchResults = [NSMutableArray arrayWithCapacity:[(NSArray *)resultArray count]];
        for (id aResult in resultArray) {
            KGOPlacemark *placemark = [KGOPlacemark placemarkWithDictionary:aResult];
            if (placemark) {
                [searchResults addObject:placemark];
            }
        }
        DLog(@"%@", searchResults);
        [self.searchDelegate searcher:self didReceiveResults:searchResults];
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
    } else if (request == _searchRequest) {
        _searchRequest = nil;
    } 
}

- (void)request:(KGORequest *)request didFailWithError:(NSError *)error
{
}

@end
