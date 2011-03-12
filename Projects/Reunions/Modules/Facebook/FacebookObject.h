#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface FacebookObject : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * owner;
@property (nonatomic, retain) NSString * date;
@property (nonatomic, retain) NSString * identifier;

@end
