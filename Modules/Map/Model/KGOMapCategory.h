#import <CoreData/CoreData.h>
#import "KGOSearchModel.h"

@class KGOPlacemark;

@interface KGOMapCategory : NSManagedObject <KGOCategory> {
    
}
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * sortOrder;
@property (nonatomic, retain) NSSet* subcategories;
@property (nonatomic, retain) NSSet* places;
@property (nonatomic, retain) KGOMapCategory * parentCategory;
@property (nonatomic, retain) NSString * subtitle;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;

@property (nonatomic, retain) ModuleTag *moduleTag;

+ (KGOMapCategory *)categoryWithPath:(NSArray *)categoryPath;

+ (KGOMapCategory *)categoryWithIdentifier:(NSString *)categoryID;
+ (KGOMapCategory *)categoryWithDictionary:(NSDictionary *)dictionary;

@end
