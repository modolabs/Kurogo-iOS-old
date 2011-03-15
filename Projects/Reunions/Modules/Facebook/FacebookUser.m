#import "FacebookUser.h"
#import "FacebookPost.h"
#import "CoreDataManager.h"
#import "Foundation+KGOAdditions.h"

NSString * const FacebookUserEntityName = @"FacebookUser";

@implementation FacebookUser
@dynamic isSelf;
@dynamic name;
@dynamic identifier;
@dynamic posts;
@dynamic likes;

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

#pragma mark - Core data generated methods

- (void)addPostsObject:(FacebookPost *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"posts" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"posts"] addObject:value];
    [self didChangeValueForKey:@"posts" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removePostsObject:(FacebookPost *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"posts" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"posts"] removeObject:value];
    [self didChangeValueForKey:@"posts" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addPosts:(NSSet *)value {    
    [self willChangeValueForKey:@"posts" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"posts"] unionSet:value];
    [self didChangeValueForKey:@"posts" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removePosts:(NSSet *)value {
    [self willChangeValueForKey:@"posts" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"posts"] minusSet:value];
    [self didChangeValueForKey:@"posts" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


- (void)addLikesObject:(FacebookPost *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"likes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"likes"] addObject:value];
    [self didChangeValueForKey:@"likes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeLikesObject:(FacebookPost *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"likes" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"likes"] removeObject:value];
    [self didChangeValueForKey:@"likes" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addLikes:(NSSet *)value {    
    [self willChangeValueForKey:@"likes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"likes"] unionSet:value];
    [self didChangeValueForKey:@"likes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeLikes:(NSSet *)value {
    [self willChangeValueForKey:@"likes" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"likes"] minusSet:value];
    [self didChangeValueForKey:@"likes" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


@end
