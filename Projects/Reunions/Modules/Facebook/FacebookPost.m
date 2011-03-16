#import "FacebookPost.h"
#import "FacebookUser.h"


@implementation FacebookPost
@dynamic date;
@dynamic identifier;
@dynamic owner;
@dynamic likes;


- (void)addLikesObject:(FacebookUser *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"likes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"likes"] addObject:value];
    [self didChangeValueForKey:@"likes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeLikesObject:(FacebookUser *)value {
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
