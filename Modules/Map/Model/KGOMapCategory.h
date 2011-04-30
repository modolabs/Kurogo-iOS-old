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
@property (nonatomic, retain) NSNumber *hasSubcategories;
@property (nonatomic, retain) NSNumber * browsable;

+ (KGOMapCategory *)categoryWithPath:(NSArray *)categoryPath;

@end
