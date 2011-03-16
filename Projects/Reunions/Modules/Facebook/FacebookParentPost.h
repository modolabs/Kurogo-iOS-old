#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FacebookPost.h"

@class FacebookComment;

@interface FacebookParentPost : FacebookPost {
@private
}
@property (nonatomic, retain) NSString * postIdentifier;
@property (nonatomic, retain) NSSet* comments;

@end
