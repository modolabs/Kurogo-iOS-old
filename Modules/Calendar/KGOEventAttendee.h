#import <CoreData/CoreData.h>

@class KGOEvent;

@interface KGOEventAttendee :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) KGOEvent * event;

@end



