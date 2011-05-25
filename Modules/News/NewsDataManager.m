
#import "NewsDataManager.h"
#import "NewsDataManager+Protected.h"
#import "CoreDataManager.h"

#define REQUEST_CATEGORIES_CHANGED 1
#define REQUEST_CATEGORIES_UNCHANGED 2
#define LIMIT 10

// 2 hours
#define NEWS_CATEGORY_EXPIRES_TIME 7200.0

NSString * const NewsTagItem            = @"item";
NSString * const NewsTagTitle           = @"title";
NSString * const NewsTagAuthor          = @"author";
NSString * const NewsTagLink            = @"link";
NSString * const NewsTagStoryId         = @"GUID";
NSString * const NewsTagImage           = @"image";
//NSString * const NewsTagFeatured        = @"harvard:featured";
//NSString * const NewsTagFeaturedImage   = @"harvard:featured_photo";
NSString * const NewsTagSummary         = @"description";
NSString * const NewsTagPostDate        = @"pubDate";
NSString * const NewsTagHasBody         = @"hasBody";
NSString * const NewsTagBody            = @"body";


@interface NewsDataManager (Private)

- (NewsCategory *)fetchCategoryFromCoreData:(NSString *)categoryID;
- (void)updateCategoriesFromNetwork;
- (void)loadStoriesFromServerForCategory:(NewsCategory *)category loadMore:(BOOL)loadMore;
- (NSArray *)fetchLatestSearchResultsFromCoreData;
- (NewsStory *)storyWithDictionary:(NSDictionary *)dict;

@end

@implementation NewsDataManager

@synthesize storiesRequest;
@synthesize searchRequests;

+ (NewsDataManager *)sharedManager {
	static NewsDataManager *s_sharedManager = nil;
	if (s_sharedManager == nil) {
		s_sharedManager = [[NewsDataManager alloc] init];
	}
	return s_sharedManager;
}

- (id) init {
    if((self = [super init])) {
        delegates = [NSMutableSet new];
        self.storiesRequest = nil;
    }
    return self;
}

- (void)registerDelegate:(id<NewsDataDelegate>)delegate {
    [delegates addObject:delegate];
}

- (void)unregisterDelegate:(id<NewsDataDelegate>)delegate {
    [delegates addObject:delegate];
}

- (void)requestCategories {
    NSArray *categories = [self fetchCategoriesFromCoreData];
    if(categories) {
        NSSet *safeDelegates = [NSSet setWithSet:delegates];
        for(id<NewsDataDelegate> delegate in safeDelegates) {
            if([delegate respondsToSelector:@selector(categoriesUpdated:)]) {
                [delegate categoriesUpdated:categories];
            }
        }
    }
    [self updateCategoriesFromNetwork];
}

- (NSArray *)fetchCategoriesFromCoreData {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isMainCategory = YES"];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"category_id" ascending:YES];
    NSArray *categoryObjects = [[CoreDataManager sharedManager] objectsForEntity:NewsCategoryEntityName matchingPredicate:predicate sortDescriptors:[NSArray arrayWithObject:sort]];
    [sort release];
    return categoryObjects;
}

- (NewsCategory *)fetchCategoryFromCoreData:(NSString *)categoryID {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category_id LIKE %@", categoryID];
    NSArray *categories =[[CoreDataManager sharedManager] objectsForEntity:NewsCategoryEntityName matchingPredicate:predicate];
    return [categories lastObject];
}

- (NSInteger)loadMoreStoriesQuantityForCategoryId:(NSString *)categoryID {
    NewsCategory *category = [self fetchCategoryFromCoreData:categoryID];
    if ([category.nextSeekId integerValue] == 0) {
        return LIMIT;
    } else {
        NSInteger remaining = [category.moreStories integerValue];
        if(remaining > LIMIT) {
            return LIMIT;
        } else {
            return remaining;
        }
    }
}

- (void)updateCategoriesFromNetwork {
    KGORequest *request = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                          module:NewsTag
                                                                            path:@"categories"
                                                                          params:nil];

    request.expectedResponseType = [NSArray class];
    
    __block NewsDataManager *blockSelf = self;
    request.handler = [[^(id result) {
        NSArray *newCategorieDicts = result;
        NSArray *oldCategories = [blockSelf fetchCategoriesFromCoreData];
		// check if the new categories are the same as the old categories
		BOOL categoriesChanged = NO;
		if ([newCategorieDicts count] == [oldCategories count]) {
			for (NSUInteger i=0; i < [newCategorieDicts count]; i++) {
                NSDictionary *newCategoryDict = [newCategorieDicts objectAtIndex:i];
                NewsCategory *oldCategory = (NewsCategory *)[oldCategories objectAtIndex:i];
                
                NSString *oldID = oldCategory.category_id;
                NSString *newID = [newCategoryDict objectForKey:@"id"];
                if (![newID isEqualToString:oldID]) {
					categoriesChanged = YES;
					break;
				}
                
                NSString *newTitle = [newCategoryDict objectForKey:@"title"];
                NSString *oldTitle = oldCategory.title;
				if (![newTitle isEqualToString:oldTitle]) {
					categoriesChanged = YES;
					break;
				}
			}
		} else {
			categoriesChanged = YES;
		}
		
		if (!categoriesChanged) {
			// categories do not need to be updated
			return REQUEST_CATEGORIES_UNCHANGED;
		}
        
        
        [[CoreDataManager sharedManager] deleteObjects:oldCategories];
		
        for (NSDictionary *categoryDict in newCategorieDicts) {
            NewsCategory *aCategory = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:NewsCategoryEntityName];
            aCategory.title = [categoryDict objectForKey:@"title"];
            aCategory.category_id = [categoryDict objectForKey:@"id"];
            aCategory.isMainCategory = [NSNumber numberWithBool:YES];
            aCategory.moreStories = [NSNumber numberWithInt:-1];
            aCategory.nextSeekId = [NSNumber numberWithInt:0];
        }
        
        [[CoreDataManager sharedManager] saveData];
        
        
        return REQUEST_CATEGORIES_CHANGED;
        
    } copy] autorelease];
    
	BOOL success = [request connect];
	if (!success) {
		DLog(@"failed to dispatch request");
	}
    
}

- (NSArray *)fetchBookmarks {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bookmarked == YES"];
    NSArray *allBookmarkedStories = [[CoreDataManager sharedManager] objectsForEntity:NewsStoryEntityName matchingPredicate:predicate];
    return allBookmarkedStories;
}

- (void)requestStoriesForCategory:(NSString *)categoryID loadMore:(BOOL)loadMore forceRefresh:(BOOL)forceRefresh {
    // load what's in CoreData
    NewsCategory *category =[self fetchCategoryFromCoreData:categoryID];
    [[[CoreDataManager sharedManager] managedObjectContext] refreshObject:category mergeChanges:NO];
    
    NSPredicate *predicate = nil;
    NSSortDescriptor *postDateSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"postDate" ascending:NO];
    NSSortDescriptor *storyIdSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"identifier" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:/*featuredSortDescriptor,*/ postDateSortDescriptor, storyIdSortDescriptor, nil];
    [storyIdSortDescriptor release];
    [postDateSortDescriptor release];
    
    predicate = [NSPredicate predicateWithFormat:@"ANY categories.category_id LIKE %@", category.category_id];
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
    
    for (id<NewsDataDelegate> delegate in delegates) {
        if([delegate respondsToSelector:@selector(storiesUpdated:forCategory:)]) {
            [delegate storiesUpdated:stories forCategory:category];
        }
    }
    
    BOOL categoryFresh;
    if(category.lastUpdated) {
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
    for (id<NewsDataDelegate> delegate in delegates) {
        if([delegate respondsToSelector:@selector(storiesDidMakeProgress:forCategoryId:)]) {
            [delegate storiesDidMakeProgress:0.0f forCategoryId:category.category_id];
        }
    }
    
    NSInteger start = 0;
    if (loadMore) {
        start = [category.nextSeekId intValue];
    }
    
    NSString *startValue = [NSString stringWithFormat:@"%d", start];
    NSInteger limit = LIMIT;
    NSString *limitValue = [NSString stringWithFormat:@"%d", limit];
    
    NSString *categoryID = category.category_id;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            startValue, @"start",
                            limitValue, @"limit",
                            categoryID, @"categoryID", 
                            @"full", @"mode", nil];
    
    KGORequest *request = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                          module:NewsTag
                                                                            path:@"stories"
                                                                          params:params];
    self.storiesRequest = request;
    
    request.expectedResponseType = [NSDictionary class];
    
    __block NewsDataManager *blockSelf = self;
    request.handler = [[^(id result) {
        NewsCategory *safeCategoryObject = [blockSelf fetchCategoryFromCoreData:categoryID];
        
        if (!loadMore) {
            // this is a refresh load, so we need to prune
            // all old stories
            
            for (NewsStory *story in safeCategoryObject.stories) {
                if(![story.bookmarked boolValue] && ([story.categories count] <= 1)) {
                    [[CoreDataManager sharedManager] deleteObject:story];
                }
            }
            safeCategoryObject.stories = [NSSet set];
        }
        
        NSDictionary *resultDict = (NSDictionary *)result;
        NSArray *stories = [resultDict objectForKey:@"stories"];
        
        for (NSDictionary *storyDict in stories) {
            NewsStory *story = [blockSelf storyWithDictionary:storyDict]; 
            NSMutableSet *mutableCategories = [NSMutableSet setWithCapacity:1];
            [mutableCategories unionSet:story.categories];
            [mutableCategories addObject:safeCategoryObject];
            story.categories = mutableCategories;
        }
        
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

- (void) search:(NSString *)searchTerms {
    
    // cancel any previous search requests
    for (KGORequest *request in self.searchRequests) {
        [request cancel];
    }
    // remove all old search results
    for (NewsStory *story in [self fetchLatestSearchResultsFromCoreData]) {
        if(![story.bookmarked boolValue] && ([story.categories count] == 0)) {
            [[CoreDataManager sharedManager] deleteObject:story];
        } else {
            story.searchResult = [NSNumber numberWithInt:0];
        }
    }
    [[CoreDataManager sharedManager] saveData];
    self.searchRequests = [NSMutableSet setWithCapacity:1];
    
    NSArray *categories = [self searchableCategories];
    for(NewsCategory *category in categories) {
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        [params setObject:searchTerms forKey:@"q"];
        [params setObject:category.category_id forKey:@"categoryID"];
    
        KGORequest *request = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                          module:NewsTag
                                                                            path:@"search"
                                                                          params:params];
        request.expectedResponseType = [NSArray class];
        request.handler = [[^(id stories) {
            
            for (NSDictionary *storyDict in stories) {
                NewsStory *story =[self storyWithDictionary:storyDict]; 
                story.searchResult = [NSNumber numberWithInt:1];
            }
        
            return [stories count];
        } copy] autorelease];                               
        
        [request connect];
        
        [self.searchRequests addObject:request];
    }
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

- (NSArray *)bookmarkedStories {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bookmarked == YES"];
    return [[CoreDataManager sharedManager] objectsForEntity:NewsStoryEntityName matchingPredicate:predicate];
}

- (void)story:(NewsStory *)story bookmarked:(BOOL)bookmarked {
    story.bookmarked = [NSNumber numberWithBool:bookmarked];
    [[CoreDataManager sharedManager] saveData];
}

- (NewsStory *)storyWithDictionary:(NSDictionary *)storyDict {
    // use existing story if it's already in the db
    NSString *GUID = [storyDict objectForKey:NewsTagStoryId];
    NewsStory *story = [[CoreDataManager sharedManager] getObjectForEntity:NewsStoryEntityName 
                                                                 attribute:@"identifier" 
                                                                     value:GUID];
    // otherwise create new
    if (!story) {
        story = (NewsStory *)[[CoreDataManager sharedManager] insertNewObjectForEntityForName:NewsStoryEntityName];
    }
    
    double unixtime = [((NSNumber *)[storyDict objectForKey:@"pubDate"]) doubleValue];
    NSDate *postDate = [NSDate dateWithTimeIntervalSince1970:unixtime];
    
    story.identifier = GUID;
    story.postDate = postDate;
    story.title = [storyDict objectForKey:NewsTagTitle];
    story.link = [storyDict objectForKey:NewsTagLink];
    story.author = [storyDict objectForKey:NewsTagAuthor];
    story.summary = [storyDict objectForKey:NewsTagSummary];
    story.hasBody = [storyDict objectForKey:NewsTagHasBody];
    if([storyDict objectForKey:NewsTagBody]) {
        story.body = [storyDict objectForKey:NewsTagBody];
    }
    
    NSDictionary *imageDict = [storyDict objectForKey:NewsTagImage];
    if (imageDict) {
        // an old thumb may already exist
        // in which case do not create a new one
        if (!story.thumbImage) {
            story.thumbImage = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:NewsImageEntityName];
        }
        story.thumbImage.url = [imageDict objectForKey:@"src"];
        story.thumbImage.thumbParent = story;
    } else {
        story.thumbImage = nil;
    }
    //story.featured = [NSNumber numberWithBool:![[storyDict objectForKey:NewsTagFeatured] isEqualToString:@"no"]]
    return story;
}

#pragma mark KGORequestDelegate

- (void)request:(KGORequest *)request didHandleResult:(NSInteger)returnValue {
    NSString *path = request.path;
    
    if ([path isEqualToString:@"stories"]) {
        NSString *categoryID = [request.getParams objectForKey:@"categoryID"];
        [self requestStoriesForCategory:categoryID loadMore:NO forceRefresh:NO];
    
    } else if ([path isEqualToString:@"search"]) {
        [self.searchRequests removeObject:request];
        
        if (self.searchRequests.count == 0) { // all searches have completed
            NSString *searchTerms = [request.getParams objectForKey:@"q"];
        
            NSArray *results = [self fetchLatestSearchResultsFromCoreData];
        
            for (id<NewsDataDelegate> delegate in delegates) {
                if ([delegate respondsToSelector:@selector(searchResults:forSearchTerms:)])
                    [delegate searchResults:results forSearchTerms:searchTerms];            
            }
        }
        
    } else if([path isEqualToString:@"categories"]) {    
        switch (returnValue) {
            case REQUEST_CATEGORIES_CHANGED:
            {
                NSArray *categories = [self fetchCategoriesFromCoreData];
                if (categories) {
                    for (id<NewsDataDelegate> delegate in delegates) {
                        if ([delegate respondsToSelector:@selector(categoriesUpdated:)]) {
                            [delegate categoriesUpdated:categories];
                        }
                    }
                }
                break;
            }
            default:
                break;
        }
    }
}

- (void)request:(KGORequest *)request didMakeProgress:(CGFloat)progress {
    if ([request.path isEqualToString:@"stories"]) {
        NSString *categoryID = [request.getParams objectForKey:@"categoryID"];
        
        for(id<NewsDataDelegate> delegate in delegates) {
            if([delegate respondsToSelector:@selector(storiesDidMakeProgress:forCategoryId:)]) {
                [delegate storiesDidMakeProgress:progress forCategoryId:categoryID];
            }
        }

    }
}

- (void)request:(KGORequest *)request didFailWithError:(NSError *)error {
    if ([request.path isEqualToString:@"stories"]) {
        NSString *categoryID = [request.getParams objectForKey:@"categoryID"];
        
        for(id<NewsDataDelegate> delegate in delegates) {
            if([delegate respondsToSelector:@selector(storiesDidFailWithCategoryId:)]) {
                [delegate storiesDidFailWithCategoryId:categoryID];
            }
        }
        
        [[KGORequestManager sharedManager] showAlertForError:error request:request];
    } else if ([request.path isEqualToString:@"categories"]) {
        NSArray *categories = [self fetchCategoriesFromCoreData];
        if ([categories count] == 0) {
            [[KGORequestManager sharedManager] showAlertForError:error request:request];
        }
    }
}

-(void)requestWillTerminate:(KGORequest *)request {
    if(request == self.storiesRequest) {
        self.storiesRequest = nil;
    }
    
    if(self.searchRequests) {
        [self.searchRequests removeObject:request];
    }
    
    request.delegate = nil;
}

@end
