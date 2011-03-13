#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FacebookPost.h"

@class FacebookComment, FacebookLike;

@interface FacebookParentPost : FacebookPost {
@private
}
@property (nonatomic, retain) NSString * commentPath;
@property (nonatomic, retain) NSSet* likes;
@property (nonatomic, retain) NSSet* comments;

@end
