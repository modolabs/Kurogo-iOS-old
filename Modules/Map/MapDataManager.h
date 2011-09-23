#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "KGORequestManager.h"
#import "KGOSearchModel.h"

@class MapDataManager, KGOPlacemark;

@protocol MapDataManagerDelegate <NSObject>

@optional

- (void)browseIndexDidComplete:(MapDataManager *)dataManager;
- (void)mapDataManager:(MapDataManager *)dataManager didReceiveChildren:(NSArray *)children forCategory:(NSString *)categoryID;
- (void)mapDataManager:(MapDataManager *)dataManager didUpdatePlacemark:(KGOPlacemark *)placemark;

@end

@interface MapDataManager : NSObject <KGORequestDelegate> {
    
    KGORequest *_indexRequest;
    KGORequest *_categoryRequest;
    KGORequest *_detailRequest;
    KGORequest *_searchRequest;
    
}

@property(nonatomic, retain) ModuleTag *moduleTag;
@property(nonatomic, assign) id<MapDataManagerDelegate> delegate;
@property(nonatomic, assign) id<KGOSearchResultsHolder> searchDelegate;

- (void)requestBrowseIndex;
- (void)requestChildrenForCategory:(NSString *)categoryID;
- (void)requestDetailsForPlacemark:(NSString *)placemarkID latitude:(CGFloat)lat longitude:(CGFloat)lon;

- (void)search:(NSString *)searchText;
- (void)searchNearby:(CLLocationCoordinate2D)coordinate;

@end
