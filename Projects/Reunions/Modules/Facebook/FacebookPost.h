#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FacebookUser;

@interface FacebookPost : NSManagedObject {
@private
}
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) FacebookUser * owner;
@property (nonatomic, retain) NSSet* likes;

@end
