#import "NewsDataController.h"
#import "CoreDataManager.h"
#import "NewsCategory.h"


static NSTimeInterval kNewsCategoryExpireTime = 7200;

@implementation NewsDataController

@synthesize currentCategory, moduleTag, delegate,
currentCategories = _currentCategories, currentStories = _currentStories;

- (BOOL)requiresKurogoServer
{
    return NO;
}

#pragma mark categories

- (NSArray *)latestCategories
{
    
    if (!_currentCategories) {    
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isMainCategory = YES AND moduleTag = %@", self.moduleTag];
        NSSortDescriptor *sort = [[[NSSortDescriptor alloc] initWithKey:@"category_id" ascending:YES] autorelease];
        NSArray *results = [[CoreDataManager sharedManager] objectsForEntity:NewsCategoryEntityName
                                                           matchingPredicate:predicate
                                                             sortDescriptors:[NSArray arrayWithObject:sort]];
        if (results.count) {
            self.currentCategories = results;
        }
    }

    return _currentCategories;
}

- (void)fetchCategories {
    NSArray *results = [self latestCategories];
    NSDate *now = [NSDate date]; 
    if (results) {
        NewsCategory *category = [results objectAtIndex:0];
        if ([category.lastUpdated timeIntervalSince1970]+kNewsCategoryExpireTime < [now timeIntervalSince1970]){
            [self requestCategoriesFromServer];
        }
        else if ([self.delegate respondsToSelector:@selector(dataController:didRetrieveCategories:)]) {
            [self.delegate dataController:self didRetrieveCategories:results];
        }
    } 
    else {
        [self requestCategoriesFromServer];
    }
}

- (NewsCategory *)categoryWithId:(NSString *)categoryId {
    if ([self.currentCategory.category_id isEqualToString:categoryId]) {
        return self.currentCategory;
    }
    /* No need to do this hear. It gets done in latestCategories
    if (!_currentCategories) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"moduleTag = %@", self.moduleTag];
        NSArray *categories = [[CoreDataManager sharedManager] objectsForEntity:NewsCategoryEntityName
                                                              matchingPredicate:predicate];
        if (categories.count) {
            self.currentCategories = categories;
        }
    }
    */
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"category_id like %@", categoryId];
    NSArray *matches = [self.currentCategories filteredArrayUsingPredicate:pred];
    if (matches.count > 1) {
        NSLog(@"warning: duplicate categories found for id %@", categoryId);
    }
    
    return [matches lastObject];
}

- (NSArray *)searchableCategories
{
    return self.currentCategories;
}

#pragma mark stories

- (BOOL)canLoadMoreStories
{
    return NO;
}

- (NSArray *)bookmarkedStories
{
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"bookmarked == YES AND ANY categories.moduleTag = %@", self.moduleTag];
    return [[CoreDataManager sharedManager] objectsForEntity:NewsStoryEntityName matchingPredicate:pred];
}

- (void)fetchBookmarks
{
    NSArray *bookmarks = [self bookmarkedStories];
    
    if ([self.delegate respondsToSelector:@selector(dataController:didRetrieveStories:)]) {
        [self.delegate dataController:self didRetrieveStories:bookmarks];
    }
}

- (void)fetchStoriesForCategory:(NSString *)categoryId
                        startId:(NSString *)startId
{
    if (categoryId && ![categoryId isEqualToString:self.currentCategory.category_id]) {
        self.currentCategory = [self categoryWithId:categoryId];
    }

    NSManagedObjectContext *context = [[CoreDataManager sharedManager] managedObjectContext];
    if ([self.currentCategory managedObjectContext] != context) {
        self.currentCategory = (NewsCategory *)[context objectWithID:[self.currentCategory objectID]];
    }
    [[[CoreDataManager sharedManager] managedObjectContext] refreshObject:self.currentCategory mergeChanges:NO];
    
    if (!self.currentCategory.lastUpdated
        || -[self.currentCategory.lastUpdated timeIntervalSinceNow] > kNewsCategoryExpireTime
        || !self.currentCategory.stories.count)
    {
        DLog(@"last updated: %@", self.currentCategory.lastUpdated);
        [self requestStoriesForCategory:categoryId afterId:nil];
        return;
    }
    
    NSSortDescriptor *dateSort = [[[NSSortDescriptor alloc] initWithKey:@"postDate" ascending:NO] autorelease];
    NSSortDescriptor *idSort = [[[NSSortDescriptor alloc] initWithKey:@"identifier" ascending:NO] autorelease];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:dateSort, idSort, nil];
    
    NSArray *results = [self.currentCategory.stories sortedArrayUsingDescriptors:sortDescriptors];
    
    if ([self.delegate respondsToSelector:@selector(dataController:didRetrieveStories:)]) {
        [self.delegate dataController:self didRetrieveStories:results];
    }
}

- (void)pruneStoriesForCategoryId:(NSString *)categoryId
{
    NewsCategory *category = nil;
    NSArray *stories = nil;
    
    if (categoryId) {
        category = [self categoryWithId:categoryId];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"bookmarked != YES"];
        stories = [[category.stories filteredSetUsingPredicate:pred] allObjects];
        
    } else if (!categoryId) {
        NSPredicate *pred = [NSPredicate predicateWithFormat:
                             @"bookmarked != YES AND ANY categories.moduleTag = %@", self.moduleTag];
        stories = [[CoreDataManager sharedManager] objectsForEntity:NewsStoryEntityName
                                                  matchingPredicate:pred];
    }
    
    [[CoreDataManager sharedManager] deleteObjects:stories];
    
    if (category) {
        category.stories = nil;
    }
    [[CoreDataManager sharedManager] saveData];
    
    if ([self.delegate respondsToSelector:@selector(dataController:didPruneStoriesForCategoryId:)]) {
        [self.delegate dataController:self didPruneStoriesForCategoryId:categoryId];
    }
}

- (void)readFeedData:(NSDictionary *)feedData
{
}

- (void)fetchSearchResultsFromStore
{
    
}

// needs override

- (void)requestCategoriesFromServer
{
    
}

- (void)requestStoriesForCategory:(NSString *)categoryId afterId:(NSString *)afterId
{
    
}

- (void)searchStories:(NSString *)searchTerms
{
    
}

- (NSArray *)latestSearchResults
{
    return nil;
}

- (NewsStory *)storyWithDictionary:(NSDictionary *)storyDict
{
    return nil;
}

- (NewsCategory *)categoryWithDictionary:(NSDictionary *)categoryDict
{
    return nil;
}

@end
