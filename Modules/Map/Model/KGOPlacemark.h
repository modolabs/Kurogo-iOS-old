#import <CoreData/CoreData.h>
#import "KGOSearchModel.h"
#import <MapKit/MapKit.h>

@class KGOMapCategory;

@interface KGOPlacemark : NSManagedObject <KGOSearchResult, MKAnnotation>
{
}

@property (nonatomic, copy) NSString * title;
@property (nonatomic, retain) NSNumber * sortOrder;

@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * geometryType;
@property (nonatomic, retain) NSData * geometry;

@property (nonatomic, retain) NSString * identifier;

@property (nonatomic, retain) NSString * street;
@property (nonatomic, retain) NSString * photoURL;
@property (nonatomic, retain) NSString * info;
@property (nonatomic, retain) NSData * photo;
@property (nonatomic, retain) NSData * userInfo;

@property (nonatomic, retain) NSNumber * bookmarked;

@property (nonatomic, retain) NSSet * categories;

+ (KGOPlacemark *)placemarkWithDictionary:(NSDictionary *)dictionary;
- (void)updateWithDictionary:(NSDictionary *)dictionary;

+ (KGOPlacemark *)placemarkWithID:(NSString *)placemarkID latitude:(CGFloat)latitude longitude:(CGFloat)longitude;

@end


