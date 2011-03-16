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
        comment = [FacebookComment commentWithID:commentID];
        // TODO: don't overwrite things that haven't changed
        comment.text = [dictionary stringForKey:@"message" nilIfEmpty:YES];
        NSString *dateString = [dictionary stringForKey:@"created_time" nilIfEmpty:YES];
        if (dateString) {
            comment.date = [FacebookModule dateFromRFC3339DateTimeString:dateString];
        }
        comment.owner = [FacebookUser userWithDictionary:[dictionary dictionaryForKey:@"from"]];
    }
    return comment;
}

+ (FacebookComment *)commentWithID:(NSString *)commentID {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier like %@", commentID];
    FacebookComment *comment = [[[CoreDataManager sharedManager] objectsForEntity:FacebookCommentEntityName matchingPredicate:pred] lastObject];
    if (!comment) {
        comment = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:FacebookCommentEntityName];
        comment.identifier = commentID;
    }
    return comment;
}

@end
