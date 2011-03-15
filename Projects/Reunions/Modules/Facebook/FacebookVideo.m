#import "FacebookVideo.h"
#import "Foundation+KGOAdditions.h"
#import "CoreDataManager.h"
#import "FacebookUser.h"
#import "FacebookComment.h"

NSString * const FacebookVideoEntityName = @"FacebookVideo";

@implementation FacebookVideo
@dynamic name;
@dynamic message;
@dynamic summary;
@dynamic thumbSrc;
@dynamic thumbData;
@dynamic src;

+ (FacebookVideo *)videoWithDictionary:(NSDictionary *)dictionary {
    FacebookVideo *video = nil;
    
    NSString *identifier = [dictionary objectForKey:@"object_id"];
    if (!identifier) {
        // doing this means we might set the video identifier either as that of
        // a Post object (if the user linked to a youtube video), or the ID of
        // a video object with no associated post ID.  the former will have
        // longer length ID's.  this may lead to duping.
        identifier = [dictionary objectForKey:@"id"];
    }
    if (identifier) {
        // force the id to be a string in case it's a number
        identifier = [NSString stringWithFormat:@"%@", identifier];
        video = [FacebookVideo videoWithID:identifier];

        video.thumbSrc = [dictionary stringForKey:@"picture" nilIfEmpty:YES];
        video.name = [dictionary stringForKey:@"name" nilIfEmpty:YES];
        video.src = [dictionary stringForKey:@"source" nilIfEmpty:YES];
        video.message = [dictionary stringForKey:@"message" nilIfEmpty:YES];
        video.summary = [dictionary stringForKey:@"description" nilIfEmpty:YES];
        
        NSDictionary *owner = [dictionary dictionaryForKey:@"from"];
        video.owner = [FacebookUser userWithDictionary:owner];
        
        NSDictionary *likes = [dictionary dictionaryForKey:@"likes"];
        if (likes) {
            //NSInteger count = [likes integerForKey:@"count"];
            for (NSDictionary *aLike in [likes arrayForKey:@"data"]) {
                FacebookUser *user = [FacebookUser userWithDictionary:aLike];
                [video addLikesObject:user];
            }
        }
        
        NSDictionary *comments = [dictionary dictionaryForKey:@"comments"];
        if (comments) {
            //NSInteger count = [comments objectForKey:@"count"];
            for (NSDictionary *commentDict in [comments arrayForKey:@"data"]) {
                FacebookComment *aComment = [FacebookComment commentWithDictionary:commentDict];
                aComment.parent = video;
            }
        }
    }
    
    return video;
}

+ (FacebookVideo *)videoWithID:(NSString *)identifier {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier like %@", identifier];
    FacebookVideo *aVideo = [[[CoreDataManager sharedManager] objectsForEntity:FacebookVideoEntityName matchingPredicate:pred] lastObject];
    if (!aVideo) {
        aVideo = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:FacebookVideoEntityName];
        aVideo.identifier = identifier;
    }
    return aVideo;
}

@end
