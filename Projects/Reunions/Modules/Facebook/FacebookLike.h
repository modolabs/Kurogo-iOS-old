#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FacebookPost.h"

@class FacebookParentPost;

@interface FacebookLike : FacebookPost {
@private
}
@property (nonatomic, retain) FacebookParentPost * parent;

@end
