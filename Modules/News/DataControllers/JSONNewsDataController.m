#import "JSONNewsDataController.h"
#import "CoreDataManager.h"
#import "Foundation+KGOAdditions.h"
#import "KGORequest.h"
#import "NewsCategory.h"

#define REQUEST_CATEGORIES_CHANGED 1
#define REQUEST_CATEGORIES_UNCHANGED 2
#define LOADMORE_LIMIT 10

// 2 hours
#define NEWS_CATEGORY_EXPIRES_TIME 7200.0

NSString * const NewsTagItem            = @"item";
NSString * const NewsTagTitle           = @"title";
NSString * const NewsTagAuthor          = @"author";
NSString * const NewsTagLink            = @"link";
NSString * const NewsTagStoryId         = @"GUID";
NSString * const NewsTagImage           = @"image";
NSString * const NewsTagSummary         = @"description";
NSString * const NewsTagPostDate        = @"pubDate";
NSString * const NewsTagHasBody         = @"hasBody";
NSString * const NewsTagBody            = @"body";

@implementation JSONNewsDataController

@synthesize storiesRequest;
@synthesize searchRequests;
@synthesize delegate, moduleTag;

#pragma mark NewsDataController
/*
- (id) init {
    self = [super init];
    if (self) {
        self.storiesRequest = nil;
    }
    return self;
}
*/

- (void)requestCategoriesFromServer {
    KGORequest *request = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                          module:self.moduleTag
                                                                            path:@"categories"
                                                                          params:nil];
    
    request.expectedResponseType = [NSArray class];
    
    __block NewsDataController *blockSelf = self;
    __block NSArray *oldCategories = _currentCategories;
    
    request.handler = [[^(id result) {
        NSArray *newCategoryDicts = (NSArray *)result;
        
        NSArray *oldCategoryIds = [oldCategories mappedArrayUsingBlock:^id(id element) {
            return [(NewsCategory *)element category_id];
        }];
        
        NSArray *newCategoryIds = [newCategoryDicts mappedArrayUsingBlock:^id(id element) {
            return [(NSDictionary *)element stringForKey:@"id" nilIfEmpty:YES];
        }];
        
        if ([oldCategoryIds isEqualToArray:newCategoryIds]) {
			// categories do not need to be updated
			return REQUEST_CATEGORIES_UNCHANGED;
		} 

        for (NewsCategory *oldCategory in oldCategories) {
            if (![newCategoryIds containsObject:oldCategory.category_id]) {
                [[CoreDataManager sharedManager] deleteObject:oldCategory];
            }
        }
        
        for (NSDictionary *categoryDict in newCategoryDicts) {
            (void)[blockSelf categoryWithDictionary:categoryDict];
        }
        
        [[CoreDataManager sharedManager] saveData];
        
        return REQUEST_CATEGORIES_CHANGED;
        
    } copy] autorelease];
    
	if (![request connect]) {
		DLog(@"failed to dispatch request");
	}
}

- (NewsCategory *)categoryWithDictionary:(NSDictionary *)categoryDict
{
    NewsCategory *category = nil;
    NSString *categoryId = [categoryDict stringForKey:@"id" nilIfEmpty:YES];
    if (categoryId) {
        category = [self categoryWithId:categoryId];
        if (!category) {
            category = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:NewsCategoryEntityName];
            category.moduleTag = self.moduleTag;
            category.category_id = categoryId;
        }
        category.title = [categoryDict stringForKey:@"title" nilIfEmpty:YES];
        category.isMainCategory = [NSNumber numberWithBool:YES];
        category.moreStories = [NSNumber numberWithInt:-1];
        category.nextSeekId = [NSNumber numberWithInt:0];
    }
    return category;
}

- (void)searchStories:(NSString *)searchTerms {
    
    // cancel any previous search requests
    for (KGORequest *request in self.searchRequests) {
        [request cancel];
    }

    // remove all old search results
    for (NewsStory *story in [self latestSearchResults]) {
        story.searchResult = [NSNumber numberWithInt:0];
    }
    [[CoreDataManager sharedManager] saveData];

    self.searchRequests = [NSMutableSet setWithCapacity:1];
    
    for (NewsCategory *category in [self searchableCategories]) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                category.category_id, @"categoryID",
                                searchTerms, @"q", nil];
        
        KGORequest *request = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                              module:self.moduleTag
                                                                                path:@"search"
                                                                              params:params];
        request.expectedResponseType = [NSArray class];
        
        __block JSONNewsDataController *blockSelf = self;
        request.handler = [[^(id stories) {
            
            for (NSDictionary *storyDict in stories) {
                NewsStory *story = [blockSelf storyWithDictionary:storyDict]; 
                story.searchResult = [NSNumber numberWithInt:1];
            }
            
            return [stories count];
        } copy] autorelease];                               
        
        [self.searchRequests addObject:request];
        [request connect];
    }
}

- (void)requestStoriesForCategory:(NSString *)categoryId afterId:(NSString *)afterId
{
    // TODO: signal that loading progress is 0

    if (![categoryId isEqualToString:self.currentCategory.category_id]) {
        self.currentCategory = [self categoryWithId:categoryId];
    }

    NSInteger start = 0;
    if (afterId) {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier = %@", afterId];
        NewsStory *story = [[_currentStories filteredArrayUsingPredicate:pred] lastObject];
        if (story) {
            NSInteger index = [_currentStories indexOfObject:story];
            if (index != NSNotFound) {
                start = index;
            }
        }
    }
    
    NSInteger moreStories = [self.currentCategory.moreStories integerValue];
    NSInteger limit = (moreStories && moreStories < LOADMORE_LIMIT) ? moreStories : LOADMORE_LIMIT;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSString stringWithFormat:@"%d", start], @"start",
                            [NSString stringWithFormat:@"%d", limit], @"limit",
                            categoryId, @"categoryID", 
                            @"full", @"mode", nil];
    
    KGORequest *request = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                          module:self.moduleTag
                                                                            path:@"stories"
                                                                          params:params];
    self.storiesRequest = request;
    
    request.expectedResponseType = [NSDictionary class];
    
    __block NewsDataController *blockSelf = self;
    __block NewsCategory *category = self.currentCategory;
    request.handler = [[^(id result) {
        NSDictionary *resultDict = (NSDictionary *)result;
        NSArray *stories = [resultDict arrayForKey:@"stories"];
        // need to bring category to local context
        // http://stackoverflow.com/questions/1554623/illegal-attempt-to-establish-a-relationship-xyz-between-objects-in-different-co
        NewsCategory *mergedCategory = nil;
        
        for (NSDictionary *storyDict in stories) {
            NewsStory *story = [blockSelf storyWithDictionary:storyDict];
            NSMutableSet *mutableCategories = [story mutableSetValueForKey:@"categories"];
            if (!mergedCategory) {
                mergedCategory = (NewsCategory *)[[story managedObjectContext] objectWithID:[category objectID]];
            }
            if (mergedCategory) {
                [mutableCategories addObject:mergedCategory];
            }
            story.categories = mutableCategories;
        }
        
        mergedCategory.moreStories = [resultDict numberForKey:@"moreStories"];
        mergedCategory.lastUpdated = [NSDate date];
        [[CoreDataManager sharedManager] saveData];
        
        return [stories count];
    } copy] autorelease];
    
    [request connect];
}

- (NewsStory *)storyWithDictionary:(NSDictionary *)storyDict {
    // use existing story if it's already in the db
    NSString *GUID = [storyDict stringForKey:NewsTagStoryId nilIfEmpty:YES];
    NewsStory *story = [[CoreDataManager sharedManager] uniqueObjectForEntity:NewsStoryEntityName 
                                                                    attribute:@"identifier" 
                                                                        value:GUID];
    // otherwise create new
    if (!story) {
        story = (NewsStory *)[[CoreDataManager sharedManager] insertNewObjectForEntityForName:NewsStoryEntityName];
        story.identifier = GUID;
    }
    
    double unixtime = [storyDict floatForKey:@"pubDate"];
    NSDate *postDate = [NSDate dateWithTimeIntervalSince1970:unixtime];
    
    story.postDate = postDate;
    story.title = [storyDict stringForKey:NewsTagTitle nilIfEmpty:YES];
    story.link = [storyDict stringForKey:NewsTagLink nilIfEmpty:YES];
    story.author = [storyDict stringForKey:NewsTagAuthor nilIfEmpty:YES];
    story.summary = [storyDict stringForKey:NewsTagSummary nilIfEmpty:YES];
    story.hasBody = [NSNumber numberWithBool:[storyDict boolForKey:NewsTagHasBody]];
    story.body = [storyDict stringForKey:NewsTagBody nilIfEmpty:YES];
    
    NSDictionary *imageDict = [storyDict dictionaryForKey:NewsTagImage];
    if (imageDict) {
        // an old thumb may already exist
        // in which case do not create a new one
        if (!story.thumbImage) {
            story.thumbImage = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:NewsImageEntityName];
        }
        story.thumbImage.url = [imageDict stringForKey:@"src" nilIfEmpty:YES];
        story.thumbImage.thumbParent = story;
    } else {
        story.thumbImage = nil;
    }
    return story;
}

//#pragma mark Additional APIs for Kurogo server
/*
- (NSInteger)loadMoreStoriesQuantityForCategoryId:(NSString *)categoryID {
    NewsCategory *category = [self fetchCategoryFromCoreData:categoryID];
    if ([category.nextSeekId integerValue] == 0) {
        return LOADMORE_LIMIT;
    } else {
        NSInteger remaining = [category.moreStories integerValue];
        if(remaining > LOADMORE_LIMIT) {
            return LOADMORE_LIMIT;
        } else {
            return remaining;
        }
    }
}
*/
/*
- (void)requestStoriesForCategory:(NSString *)categoryID loadMore:(BOOL)loadMore forceRefresh:(BOOL)forceRefresh {
    // load what's in CoreData
    NewsCategory *category =[self fetchCategoryFromCoreData:categoryID];
    [[[CoreDataManager sharedManager] managedObjectContext] refreshObject:category mergeChanges:NO];
    
    NSPredicate *predicate = nil;
    NSSortDescriptor *postDateSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"postDate" ascending:NO];
    NSSortDescriptor *storyIdSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"identifier" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObjects://featuredSortDescriptor,
                                postDateSortDescriptor, storyIdSortDescriptor, nil];
    [storyIdSortDescriptor release];
    [postDateSortDescriptor release];
    
    predicate = [NSPredicate predicateWithFormat:@"ANY categories.category_id LIKE %@ AND ANY categories.moduleTag = %@", category.category_id, self.moduleTag];
    NSArray *results = [[CoreDataManager sharedManager] objectsForEntity:NewsStoryEntityName matchingPredicate:predicate sortDescriptors:sortDescriptors];
    
    // grab the first featured story from the list, regardless of pubdate
    //NSArray *featuredStories = [results filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(featured == YES)"]
    NSArray *stories;
    NewsStory *featuredStory = nil;
    //if ([featuredStories count]) {
    //    featuredStory = [featuredStories objectAtIndex:0];
    //}
    
    NSMutableArray *storyCandidates = [NSMutableArray arrayWithArray:results];
    
    if ([storyCandidates containsObject:featuredStory]) {
        [storyCandidates removeObject:featuredStory];
        stories = [[NSArray arrayWithObject:featuredStory] arrayByAddingObjectsFromArray:storyCandidates];
    } else {
        stories = storyCandidates;
    }
    
    if ([self.delegate respondsToSelector:@selector(storiesUpdated:forCategory:)]) {
        [self.delegate storiesUpdated:stories forCategory:category];
    }
    
    BOOL categoryFresh;
    if (category.lastUpdated) {
        categoryFresh = (-[category.lastUpdated timeIntervalSinceNow] < NEWS_CATEGORY_EXPIRES_TIME);
    } else {
        categoryFresh = NO;
    }
    
    if (loadMore || ([results count] == 0) || !categoryFresh || forceRefresh) {
        [self loadStoriesFromServerForCategory:category loadMore:loadMore];
        // this creates a loop which will keep trying until there is at least something in this category
    }
}

-(void) loadStoriesFromServerForCategory:(NewsCategory *)category loadMore:(BOOL)loadMore {
    if ([self busy]) {
        // refuse to service request
        // could cancel old request instead
        return;
    }
    
    // show that downloading is beginning
    if([self.delegate respondsToSelector:@selector(storiesDidMakeProgress:forCategoryId:)]) {
        [self.delegate storiesDidMakeProgress:0.0f forCategoryId:category.category_id];
    }
    
    NSInteger start = 0;
    if (loadMore) {
        start = [category.nextSeekId intValue];
    }
    
    NSString *startValue = [NSString stringWithFormat:@"%d", start];
    NSInteger limit = LOADMORE_LIMIT;
    NSString *limitValue = [NSString stringWithFormat:@"%d", limit];
    
    NSString *categoryID = category.category_id;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            startValue, @"start",
                            limitValue, @"limit",
                            categoryID, @"categoryID", 
                            @"full", @"mode", nil];
    
    KGORequest *request = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                          module:self.moduleTag
                                                                            path:@"stories"
                                                                          params:params];
    self.storiesRequest = request;
    
    request.expectedResponseType = [NSDictionary class];
    
    __block NewsDataController *blockSelf = self;
    request.handler = [[^(id result) {
        NewsCategory *safeCategoryObject = [blockSelf fetchCategoryFromCoreData:categoryID];
        
        if (!loadMore) {
            // this is a refresh load, so we need to prune
            // all old stories
            
            for (NewsStory *story in safeCategoryObject.stories) {
                if (![story.bookmarked boolValue] && ([story.categories count] <= 1)) {
                    [[CoreDataManager sharedManager] deleteObject:story];
                }
            }
            safeCategoryObject.stories = [NSSet set];
        }
        
        NSDictionary *resultDict = (NSDictionary *)result;
        NSArray *stories = [resultDict arrayForKey:@"stories"];
        
        for (NSDictionary *storyDict in stories) {
            NewsStory *story = [blockSelf storyWithDictionary:storyDict]; 
            NSMutableSet *mutableCategories = [NSMutableSet setWithCapacity:1];
            [mutableCategories unionSet:story.categories];
            [mutableCategories addObject:safeCategoryObject];
            story.categories = mutableCategories;
        }
        
        // TODO: is [resultDict objectForKey:@"moreStories"] really a set?
        safeCategoryObject.moreStories = [resultDict objectForKey:@"moreStories"];
        safeCategoryObject.nextSeekId = [NSNumber numberWithInt:(start + limit)];
        safeCategoryObject.lastUpdated = [NSDate date];
        [[CoreDataManager sharedManager] saveData];

        return [stories count];
    } copy] autorelease];
    
    [request connect];
}

- (BOOL) busy {
    return  (self.storiesRequest != nil);
}
    
- (NSArray *)searchableCategories {
    return [self fetchCategoriesFromCoreData];
}

- (NSArray *)fetchLatestSearchResultsFromCoreData {
    NSPredicate *predicate = nil;
    NSSortDescriptor *relevanceSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"searchResult" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:relevanceSortDescriptor];
    [relevanceSortDescriptor release];
    
    predicate = [NSPredicate predicateWithFormat:@"searchResult > 0"];
    
    // show everything that comes back
    NSArray *results = [[CoreDataManager sharedManager] objectsForEntity:NewsStoryEntityName matchingPredicate:predicate sortDescriptors:sortDescriptors];
    
    return results;
}

- (void)saveImageData:(NSData *)data url:(NSString *)url {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"url LIKE %@", url];
    NSArray *images = [[CoreDataManager sharedManager] 
                       objectsForEntity:NewsImageEntityName
                       matchingPredicate:predicate];
    for (NewsImage *image in images) {
        image.data = data;
    }
    [[CoreDataManager sharedManager] saveData];
}

- (void)story:(NewsStory *)story bookmarked:(BOOL)bookmarked {
    story.bookmarked = [NSNumber numberWithBool:bookmarked];
    [[CoreDataManager sharedManager] saveData];
}
*/

- (NSArray *)latestSearchResults
{
    NSPredicate *predicate = nil;
    NSSortDescriptor *relevanceSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"searchResult" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:relevanceSortDescriptor];
    [relevanceSortDescriptor release];
    
    predicate = [NSPredicate predicateWithFormat:@"searchResult > 0"];
    
    // show everything that comes back
    NSArray *results = [[CoreDataManager sharedManager] objectsForEntity:NewsStoryEntityName
                                                       matchingPredicate:predicate
                                                         sortDescriptors:sortDescriptors];
    return results;
}

- (void)fetchSearchResultsFromStore
{
    NSArray *results = [self latestSearchResults];
    if (results && [self.delegate respondsToSelector:@selector(dataController:didRetrieveStories:)]) {
        [self.delegate dataController:self didRetrieveStories:results];
    }
}

#pragma mark KGORequestDelegate

- (void)request:(KGORequest *)request didHandleResult:(NSInteger)returnValue {
    NSString *path = request.path;
    
    if (request == self.storiesRequest) {
        NSString *categoryId = [request.getParams objectForKey:@"categoryID"];
        NSString *startId = [request.getParams objectForKey:@"start"];
        [self fetchStoriesForCategory:categoryId startId:startId];
    
    } else if ([path isEqualToString:@"search"]) {
        [self.searchRequests removeObject:request];
        
        if (self.searchRequests.count == 0) { // all searches have completed
            //NSString *searchTerms = [request.getParams objectForKey:@"q"];
        
            [self fetchSearchResultsFromStore];

            /*
            if ([self.delegate respondsToSelector:@selector(didReceiveSearchResults:forSearchTerms:)]) {
                [self.delegate didReceiveSearchResults:results forSearchTerms:searchTerms];            
            }
             */
        }
        
    } else if([path isEqualToString:@"categories"]) {    
        switch (returnValue) {
            case REQUEST_CATEGORIES_CHANGED:
            {
                [self fetchCategories];
                /*
                NSArray *categories = [self fetchCategoriesFromStore];
                if (categories) {
                    if ([self.delegate respondsToSelector:@selector(categoriesUpdated:)]) {
                        [self.delegate categoriesUpdated:categories];
                    }
                }
                 */
                break;
            }
            default:
                break;
        }
    }
}

- (void)request:(KGORequest *)request didMakeProgress:(CGFloat)progress {
    if (request == self.storiesRequest) {
        //NSString *categoryID = [request.getParams objectForKey:@"categoryID"];
        
        // TODO: see if progress value needs tweaking
        
        if ([self.delegate respondsToSelector:@selector(dataController:didMakeProgress:)]) {
            [self.delegate dataController:self didMakeProgress:progress];
        }
    }
}

- (void)request:(KGORequest *)request didFailWithError:(NSError *)error {
    if (request == self.storiesRequest) {
        //NSString *categoryID = [request.getParams objectForKey:@"categoryID"];
        
        //if ([self.delegate respondsToSelector:@selector(storiesDidFailWithCategoryId:)]) {
        //    [self.delegate storiesDidFailWithCategoryId:categoryID];
        //}
        
        if ([self.delegate respondsToSelector:@selector(dataController:didFailWithCategoryId:)]) {
            [self.delegate dataController:self didFailWithCategoryId:self.currentCategory.category_id];
        }
        
        [[KGORequestManager sharedManager] showAlertForError:error request:request];
        
    } else if ([request.path isEqualToString:@"categories"]) {
        [[KGORequestManager sharedManager] showAlertForError:error request:request];

        // don't call -fetchCategories since it may issue another request
        NSArray *existingCategories = [self latestCategories];
        if (existingCategories && [self.delegate respondsToSelector:@selector(dataController:didRetrieveCategories:)]) {
            [self.delegate dataController:self didRetrieveCategories:existingCategories];
        }
    }
}

- (void)requestWillTerminate:(KGORequest *)request {
    if (request == self.storiesRequest) {
        self.storiesRequest = nil;
        
    } else if ([self.searchRequests containsObject:request]) {
        [self.searchRequests removeObject:request];
    }
}

@end
