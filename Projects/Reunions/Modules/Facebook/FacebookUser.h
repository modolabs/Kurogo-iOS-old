#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FacebookPost;

@interface FacebookUser : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSNumber * isSelf;

// this is here for associating user names with known posts
// not for getting an exhaustive list of posts by the user
@property (nonatomic, retain) FacebookPost * posts;

+ (FacebookUser *)userWithID:(NSString *)identifier;
+ (FacebookUser *)userWithDictionary:(NSDictionary *)dictionary;

@end
