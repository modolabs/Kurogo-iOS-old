/* This is the cached counterpart to ArcGISMapSearchResultAnnotation
 * (defined in MapSearchResultAnnotation.h)
 *
 */

#import <CoreData/CoreData.h>
#import "MapSearchResultAnnotation.h"

@interface MapSavedAnnotation :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSData * info;
@property (nonatomic, retain) NSNumber * isBookmark;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * street;
@property (nonatomic, retain) NSNumber * sortOrder;

@end



