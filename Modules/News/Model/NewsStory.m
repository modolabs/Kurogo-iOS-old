#import "NewsStory.h"
#import "NewsImage.h"
#import "KGOAppDelegate+ModuleAdditions.h"

@implementation NewsStory
@dynamic body;
@dynamic author;
@dynamic read;
@dynamic featured;
@dynamic hasBody;
@dynamic identifier;
@dynamic link;
@dynamic postDate;
@dynamic title;
@dynamic topStory;
@dynamic summary;
@dynamic searchResult;
@dynamic bookmarked;
@dynamic categories;
@dynamic thumbImage;
@dynamic featuredImage;

@synthesize moduleTag;

- (void)addCategoriesObject:(NSManagedObject *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"categories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"categories"] addObject:value];
    [self didChangeValueForKey:@"categories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeCategoriesObject:(NSManagedObject *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"categories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"categories"] removeObject:value];
    [self didChangeValueForKey:@"categories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addCategories:(NSSet *)value {    
    [self willChangeValueForKey:@"categories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"categories"] unionSet:value];
    [self didChangeValueForKey:@"categories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeCategories:(NSSet *)value {
    [self willChangeValueForKey:@"categories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"categories"] minusSet:value];
    [self didChangeValueForKey:@"categories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

#pragma mark - KGOSearchResult

- (NSString *)subtitle {
    return self.summary;
}

- (BOOL)isBookmarked {
    return [self.bookmarked boolValue];
}

- (void)addBookmark {
    if (![self isBookmarked]) {
        self.bookmarked = [NSNumber numberWithBool:YES];
    }
    self.searchResult = [NSNumber numberWithInt:0];
}

- (void)removeBookmark {
    if ([self isBookmarked]) {
        self.bookmarked = [NSNumber numberWithBool:NO];
    }
}

- (BOOL)didGetSelected:(id)selector
{
    if ([self.hasBody boolValue]) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:self, @"story", nil];
        return [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail
                                      forModuleTag:self.moduleTag
                                            params:params];
    } else if (self.link.length) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.link]];
        return YES;
    }
    return NO;
}

@end
