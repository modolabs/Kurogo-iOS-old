#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FacebookPost;

@interface FacebookUser : NSManagedObject {
@private
}
@property (nonatomic, retain) NSNumber * isSelf;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSSet* posts;
@property (nonatomic, retain) NSSet* likes;

+ (FacebookUser *)userWithID:(NSString *)anIdentifier;
+ (FacebookUser *)userWithDictionary:(NSDictionary *)dictionary;

@end
