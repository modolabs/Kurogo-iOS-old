#import <CoreData/CoreData.h>


@interface NewsCategory : NSManagedObject

@property (nonatomic, retain) NSNumber *category_id;
@property (nonatomic, retain) NSNumber *expectedCount;
@property (nonatomic, retain) NSDate *lastUpdated;
@property (nonatomic, retain) NSSet *stories;
@property (nonatomic, retain) NSString *title;

@end
