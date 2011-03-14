#import "NewsDataManager.h"
#import "CoreDataManager.h"

typedef int NewsCategoryId;

#define REQUEST_CATEGORIES_CHANGED 1
#define REQUEST_CATEGORIES_UNCHANGED 2

@interface NewsDataManager (Private)

- (NSArray *)fetchCategoriesFromCoreData;
- (void)updateCategoriesFromNetwork;

@end

@implementation NewsDataManager

@synthesize categoriesDelegate;

+ (NewsDataManager *)sharedManager {
	static NewsDataManager *s_sharedManager = nil;
	if (s_sharedManager == nil) {
		s_sharedManager = [[NewsDataManager alloc] init];
	}
	return s_sharedManager;
}

- (void)requestCategories:(id<NewsCategoriesDelegate>)delegate {
    self.categoriesDelegate = delegate;
    NSArray *categories = [self fetchCategoriesFromCoreData];
    [delegate categoriesUpdated:categories];
    [self updateCategoriesFromNetwork];
}

- (NSArray *)fetchCategoriesFromCoreData {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isMainCategory = YES"];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"category_id" ascending:YES];
    NSArray *categoryObjects = [[CoreDataManager sharedManager] objectsForEntity:NewsCategoryEntityName matchingPredicate:predicate sortDescriptors:[NSArray arrayWithObject:sort]];
    [sort release];
    return categoryObjects;
}

- (void)updateCategoriesFromNetwork {
    KGORequest *request = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                          module:NewsTag
                                                                            path:@"categories"
                                                                          params:nil];
    request.expectedResponseType = [NSArray class];
    request.handler = [[^(id result) {
        NSArray *newCategoryTitles = result;
        NSArray *oldCategories = [self fetchCategoriesFromCoreData];                
        
		// check if the new categories are the same as the old categories
		BOOL categoriesChanged = NO;
		if([newCategoryTitles count] == [oldCategories count]) {
			for (NSUInteger i=0; i < [newCategoryTitles count]; i++) {
				NSString *newCategoryTitle = [newCategoryTitles objectAtIndex:i];
				NSString *oldCategoryTitle = ((NewsCategory *)[oldCategories objectAtIndex:i]).title;
				if (![newCategoryTitle isEqualToString:oldCategoryTitle]) {
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
		
        for (NewsCategoryId i = 0; i < [result count]; i++) {
            NSString *categoryTitle = [result objectAtIndex:i];
            NewsCategory *aCategory = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:NewsCategoryEntityName];
            aCategory.title = categoryTitle;
            aCategory.category_id = [NSNumber numberWithInt:i];
            aCategory.isMainCategory = [NSNumber numberWithBool:YES];
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

#pragma mark KGORequestDelegate


- (void)request:(KGORequest *)request didHandleResult:(NSInteger)returnValue {
    NSArray *categories;
    
    switch (returnValue) {
        case REQUEST_CATEGORIES_CHANGED:
            categories = [self fetchCategoriesFromCoreData];
            [self.categoriesDelegate categoriesUpdated:categories];
            break;
            
        default:
            break;
    }
}

-(void)requestWillTerminate:(KGORequest *)request {
    request.delegate = nil;
}

@end
