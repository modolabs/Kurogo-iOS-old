#import "FacebookUser.h"
#import "FacebookPost.h"
#import "CoreDataManager.h"
#import "Foundation+KGOAdditions.h"

NSString * const FacebookUserEntityName = @"FacebookUser";

@implementation FacebookUser
@dynamic name;
@dynamic identifier;
@dynamic isSelf;
@dynamic posts;

+ (FacebookUser *)userWithID:(NSString *)anIdentifier {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier like %@", anIdentifier];
    FacebookUser *user = [[[CoreDataManager sharedManager] objectsForEntity:FacebookUserEntityName matchingPredicate:pred] lastObject];
    if (!user) {
        user = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:FacebookUserEntityName];
        user.identifier = anIdentifier;
    }
    return user;
}

+ (FacebookUser *)userWithDictionary:(NSDictionary *)dictionary {
    FacebookUser *user = nil;
    NSString *anIdentifier = [dictionary stringForKey:@"id" nilIfEmpty:YES];
    NSString *name = [dictionary stringForKey:@"name" nilIfEmpty:YES];
    if (anIdentifier) {
        user = [FacebookUser userWithID:anIdentifier];
    }
    if (name && ![name isEqualToString:user.name]) {
        user.name = name;
    }
    return user;
}

@end
