#import <CoreData/CoreData.h>
#import "KGOSearchModel.h"

@class KGOEvent;

@interface KGOEventContactInfo : NSManagedObject 
{
}

@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * displayText;
@property (nonatomic, retain) NSString * contact;
@property (nonatomic, retain) KGOEvent * event;

@end



