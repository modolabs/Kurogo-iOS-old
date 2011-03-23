
#import "NewsDataManager.h"
#import "CoreDataManager.h"

#define REQUEST_CATEGORIES_CHANGED 1
#define REQUEST_CATEGORIES_UNCHANGED 2
#define LIMIT 10

NSString * const NewsTagItem            = @"item";
NSString * const NewsTagTitle           = @"title";
NSString * const NewsTagAuthor          = @"author";
NSString * const NewsTagLink            = @"link";
NSString * const NewsTagStoryId         = @"GUID";
NSString * const NewsTagImage              = @"image";
//NSString * const NewsTagFeatured        = @"harvard:featured";
//NSString * const NewsTagFeaturedImage   = @"harvard:featured_photo";
NSString * const NewsTagSummary         = @"description";
NSString * const NewsTagPostDate        = @"pubDate";
NSString * const NewsTagBody            = @"body";


@interface NewsDataManager (Private)

- (NSArray *)fetchCategoriesFromCoreData;
- (NewsCategory *)fetchCategoryFromCoreData:(NewsCategoryId)categoryID;
- (void)updateCategoriesFromNetwork;
- (void)loadStoriesFromServerForCategory:(NewsCategory *)category loadMore:(BOOL)loadMore;

@end

@implementation NewsDataManager

@synthesize storiesRequest;

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
        for(id<NewsDataDelegate> delegate in delegates) {
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

- (NewsCategory *)fetchCategoryFromCoreData:(NewsCategoryId)categoryID {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category_id LIKE %@", categoryID];
    NSArray *categories =[[CoreDataManager sharedManager] objectsForEntity:NewsCategoryEntityName matchingPredicate:predicate];
    return [categories lastObject];
}

- (NSInteger)loadMoreStoriesQuantityForCategoryId:(NewsCategoryId)categoryID {
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
    request.handler = [[^(id result) {
        NSArray *newCategorieDicts = result;
        NSArray *oldCategories = [self fetchCategoriesFromCoreData];                
        
		// check if the new categories are the same as the old categories
		BOOL categoriesChanged = NO;
		if([newCategorieDicts count] == [oldCategories count]) {
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
		
		if(!categoriesChanged) {
			// categories do not need to be updated
			return REQUEST_CATEGORIES_UNCHANGED;
		}
        
        
        [[CoreDataManager sharedManager] deleteObjects:oldCategories];		
		NSMutableArray *newCategories = [NSMutableArray arrayWithCapacity:[result count]];
		
        for (NSDictionary *categoryDict in newCategorieDicts) {
            NewsCategory *aCategory = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:NewsCategoryEntityName];
            aCategory.title = [categoryDict objectForKey:@"title"];
            aCategory.category_id = [categoryDict objectForKey:@"id"];
            aCategory.isMainCategory = [NSNumber numberWithBool:YES];
            aCategory.moreStories = [NSNumber numberWithInt:-1];
            aCategory.nextSeekId = [NSNumber numberWithInt:0];
            [newCategories addObject:aCategory];
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

- (void)requestStoriesForCategory:(NewsCategoryId)categoryID loadMore:(BOOL)loadMore {
    // load what's in CoreData
    NewsCategory *category =[self fetchCategoryFromCoreData:categoryID];
    [[[CoreDataManager sharedManager] managedObjectContext] refreshObject:category mergeChanges:NO];
    
    NSPredicate *predicate = nil;
    NSSortDescriptor *postDateSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"postDate" ascending:NO];
    NSSortDescriptor *storyIdSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"story_id" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:/*featuredSortDescriptor,*/ postDateSortDescriptor, storyIdSortDescriptor, nil];
    [storyIdSortDescriptor release];
    [postDateSortDescriptor release];
    
    predicate = [NSPredicate predicateWithFormat:@"ANY categories.category_id LIKE %@", category.category_id];
    
    // if maxLength == 0, nothing's been loaded from the server this session -- show up to 10 results from core data
    // else show up to maxLength
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
    
    if (loadMore || ([results count] == 0)) {
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
    for(id<NewsDataDelegate> delegate in delegates) {
        if([delegate respondsToSelector:@selector(storiesDidMakeProgress:forCategoryId:)]) {
            [delegate storiesDidMakeProgress:0.0f forCategoryId:category.category_id];
        }
    }
    
    NSInteger start;
    if(loadMore) {
        start = [category.nextSeekId intValue];
    } else {
        start = 0;
    }
    
    NSString *startValue = [NSString stringWithFormat:@"%d", start];
    NSInteger limit = LIMIT;
    NSString *limitValue = [NSString stringWithFormat:@"%d", limit];
    
    NewsCategoryId categoryID = category.category_id;
    
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
    request.handler = [[^(id result) {
        NewsCategory *safeCategoryObject = [self fetchCategoryFromCoreData:categoryID];
        
        NSDictionary *resultDict = (NSDictionary *)result;
        NSArray *stories = [resultDict objectForKey:@"stories"];
        
        for (NSDictionary *storyDict in stories) {
            // use existing story if it's already in the db
            NSString *GUID = [storyDict objectForKey:NewsTagStoryId];
            NewsStory *story = [[CoreDataManager sharedManager] getObjectForEntity:NewsStoryEntityName 
                                                                         attribute:@"story_id" 
                                                                             value:GUID];
            // otherwise create new
            if (!story) {
                story = (NewsStory *)[[CoreDataManager sharedManager] insertNewObjectForEntityForName:NewsStoryEntityName];
            }
            
            double unixtime = [((NSNumber *)[storyDict objectForKey:@"pubDate"]) doubleValue];
            NSTimeInterval miliseconds = unixtime * 1000.;
            NSDate *postDate = [NSDate dateWithTimeIntervalSince1970:miliseconds];
            
            story.story_id = GUID;
            story.postDate = postDate;
            story.title = [storyDict objectForKey:NewsTagTitle];
            story.link = [storyDict objectForKey:NewsTagLink];
            story.author = [storyDict objectForKey:NewsTagAuthor];
            story.summary = [storyDict objectForKey:NewsTagSummary];
            if([storyDict objectForKey:NewsTagBody]) {
                story.body = [storyDict objectForKey:NewsTagBody];
            }
            
            story.categories = [NSSet setWithObject:safeCategoryObject];
                                
            
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
            //story.featured = [NSNumber numberWithBool:![[storyDict objectForKey:NewsTagFeatured] isEqualToString:@"no"]];
            
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

#pragma mark KGORequestDelegate

- (void)request:(KGORequest *)request didHandleResult:(NSInteger)returnValue {
    NSArray *categories;
    
    NSString *path = request.path;
    
    if([path isEqualToString:@"stories"]) {
        NSString *categoryID = [request.getParams objectForKey:@"categoryID"];
        [self requestStoriesForCategory:categoryID loadMore:NO];
        return;
    
    } else if([path isEqualToString:@"categories"]) {
    
        switch (returnValue) {
            case REQUEST_CATEGORIES_CHANGED:
                categories = [self fetchCategoriesFromCoreData];
                for(id<NewsDataDelegate> delegate in delegates) {
                    if([delegate respondsToSelector:@selector(categoriesUpdated:)]) {
                        [delegate categoriesUpdated:categories];
                    }
                }
                break;
            
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

-(void)requestWillTerminate:(KGORequest *)request {
    if(request == self.storiesRequest) {
        self.storiesRequest = nil;
    }
    
    request.delegate = nil;
}

@end
