#import <CoreData/CoreData.h>
#import "KGOSearchModel.h"

@interface RecentSearch :  NSManagedObject <KGOSearchResult>
{
}

@property (nonatomic, retain) NSString * module;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * date;

@end



