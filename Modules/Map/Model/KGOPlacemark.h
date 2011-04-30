#import <CoreData/CoreData.h>
#import "KGOSearchModel.h"
#import <MapKit/MapKit.h>

@class KGOMapCategory;

@interface KGOPlacemark : NSManagedObject <KGOSearchResult, MKAnnotation>
{
}

@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * street;
@property (nonatomic, retain) NSString * geometryType;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * photoURL;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSData * geometry;
@property (nonatomic, retain) NSString * info;
@property (nonatomic, retain) NSNumber * sortOrder;
@property (nonatomic, retain) NSData * photo;
@property (nonatomic, retain) NSNumber * bookmarked;
@property (nonatomic, retain) KGOMapCategory *category;

+ (KGOPlacemark *)placemarkWithDictionary:(NSDictionary *)dictionary;
+ (KGOPlacemark *)placemarkWithID:(NSString *)placemarkID categoryPath:(NSArray *)categoryPath;
- (void)updateWithDictionary:(NSDictionary *)dictionary;

@end


