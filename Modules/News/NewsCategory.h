/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import <CoreData/CoreData.h>


@interface NewsCategory : NSManagedObject

@property (nonatomic, retain) NSNumber *category_id;
@property (nonatomic, retain) NSNumber *expectedCount;
@property (nonatomic, retain) NSNumber *isMainCategory;
@property (nonatomic, retain) NSDate *lastUpdated;
@property (nonatomic, retain) NSSet *stories;
@property (nonatomic, retain) NSString *title;

@end
