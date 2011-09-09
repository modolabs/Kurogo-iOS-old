#import "NewsDataController.h"
#import "CoreDataManager.h"
#import "NewsCategory.h"
#import "Foundation+KGOAdditions.h"

static NSString * const FeedListModifiedDateKey = @"feedListModifiedDateArray";
//static NSTimeInterval kNewsCategoryExpireTime = 7200;

@implementation NewsDataController

@synthesize currentCategory, moduleTag, delegate, searchDelegate,
currentCategories = _currentCategories, currentStories = _currentStories;

- (BOOL)requiresKurogoServer
{
    return NO;
}

- (NSDate *)feedListModifiedDate
{
    NSDictionary *modDates = [[NSUserDefaults standardUserDefaults] dictionaryForKey:FeedListModifiedDateKey];
    NSDate *result = [modDates dateForKey:self.moduleTag];
    if ([result isKindOfClass:[NSDate class]]) {
        return result;
    }
    return nil;
}

- (void)setFeedListModifiedDate:(NSDate *)date
{
    NSDictionary *modDates = [[NSUserDefaults standardUserDefaults] dictionaryForKey:FeedListModifiedDateKey];
    NSMutableDictionary *mutableModDates = modDates ? [[modDates mutableCopy] autorelease] : [NSMutableDictionary dictionary];
    if (self.moduleTag) {
        [mutableModDates setObject:date forKey:self.moduleTag];
    } else {
        NSLog(@"Warning: NewsDataController moduleTag not set, cannot save preferences");
    }
    [[NSUserDefaults standardUserDefaults] setObject:mutableModDates forKey:FeedListModifiedDateKey];
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

- (void)fetchCategories
{
    NSDate *lastUpdate = [self feedListModifiedDate];
    NSArray *results = [self latestCategories];
    if (results.count && lastUpdate && [lastUpdate timeIntervalSinceNow] + NEWS_CATEGORY_EXPIRES_TIME >= 0) {
        [self.delegate dataController:self didRetrieveCategories:results];
    } else {
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
    if ([self.currentCategory.moreStories intValue] > 0)
        return YES;
    
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
        || -[self.currentCategory.lastUpdated timeIntervalSinceNow] > NEWS_CATEGORY_EXPIRES_TIME
        // TODO: make sure the following doesn't result an infinite loop if stories legitimately don't exist
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
