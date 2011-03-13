#import "FacebookComment.h"
#import "FacebookParentPost.h"
#import "Foundation+KGOAdditions.h"
#import "CoreDataManager.h"
#import "FacebookModule.h"
#import "FacebookUser.h"

NSString * const FacebookCommentEntityName = @"FacebookComment";


@implementation FacebookComment
@dynamic text;
@dynamic parent;

+ (FacebookComment *)commentWithDictionary:(NSDictionary *)dictionary {
    FacebookComment *comment = nil;
    NSString *commentID = [dictionary stringForKey:@"id" nilIfEmpty:YES];
    if (commentID) {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier like %@", commentID];
        comment = [[[CoreDataManager sharedManager] objectsForEntity:FacebookCommentEntityName matchingPredicate:pred] lastObject];
        if (!comment) {
            comment = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:FacebookCommentEntityName];
            comment.identifier = commentID;
            comment.text = [dictionary stringForKey:@"message" nilIfEmpty:YES];
            NSString *dateString = [dictionary stringForKey:@"created_time" nilIfEmpty:YES];
            if (dateString) {
                comment.date = [FacebookModule dateFromRFC3339DateTimeString:dateString];
            }
            comment.owner = [FacebookUser userWithDictionary:[dictionary dictionaryForKey:@"from"]];
        }
    }
    return comment;
}

@end
