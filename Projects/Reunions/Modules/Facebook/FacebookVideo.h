#import "FacebookParentPost.h"


@interface FacebookVideo : FacebookParentPost {
@private
}
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSString * thumbSrc;
@property (nonatomic, retain) NSData * thumbData;
@property (nonatomic, retain) NSString * link;
@property (nonatomic, retain) NSString * src;

+ (FacebookVideo *)videoWithDictionary:(NSDictionary *)dictionary;
+ (FacebookVideo *)videoWithID:(NSString *)identifier;

@end
