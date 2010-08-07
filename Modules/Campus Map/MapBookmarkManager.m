#import "MapBookmarkManager.h"
#import "CoreDataManager.h"

@interface MapBookmarkManager (Private)

- (MapSavedAnnotation *)savedAnnotationWithAnnotation:(ArcGISMapAnnotation *)annotation;
- (void)refreshBookmarks;

@end



static MapBookmarkManager* s_mapBookmarksManager = nil;

@implementation MapBookmarkManager
@synthesize bookmarks = _bookmarks;

#pragma mark Creation and initialization

+ (MapBookmarkManager*)defaultManager
{
	if (nil == s_mapBookmarksManager) {
		s_mapBookmarksManager = [[MapBookmarkManager alloc] init];
	}
	return s_mapBookmarksManager;
}

- (id)init
{
	if (self = [super init]) {
        [self refreshBookmarks];
	}
	
	return self;
}

- (void)dealloc
{
	[_bookmarks release];
	[super dealloc];
}

- (void)refreshBookmarks {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"isBookmark == YES"];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES];
    self.bookmarks = [[CoreDataManager objectsForEntity:CampusMapAnnotationEntityName
                                      matchingPredicate:pred
                                        sortDescriptors:[NSArray arrayWithObject:sort]] mutableCopy];
}

- (void)pruneNonBookmarks {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"isBookmark == NO"];
    NSArray *nonBookmarks = [CoreDataManager objectsForEntity:CampusMapAnnotationEntityName
                                            matchingPredicate:pred];
    for (MapSavedAnnotation *nonBookmark in nonBookmarks) {
        [CoreDataManager deleteObject:nonBookmark];
    }
}

#pragma mark Bookmark Management

- (MapSavedAnnotation *)savedAnnotationForID:(NSString *)uniqueID {
    MapSavedAnnotation *saved = (MapSavedAnnotation *)[CoreDataManager getObjectForEntity:CampusMapAnnotationEntityName
                                                                                attribute:@"id"
                                                                                    value:uniqueID];
    return saved;
}

- (MapSavedAnnotation *)savedAnnotationWithAnnotation:(ArcGISMapAnnotation *)annotation {
    MapSavedAnnotation *savedAnnotation = [CoreDataManager insertNewObjectForEntityForName:CampusMapAnnotationEntityName];
    
    savedAnnotation.id = annotation.uniqueID;
    savedAnnotation.latitude = [NSNumber numberWithFloat:annotation.coordinate.latitude];
    savedAnnotation.longitude = [NSNumber numberWithFloat:annotation.coordinate.longitude];
    if (annotation.name) savedAnnotation.name = annotation.name;
    if (annotation.street) savedAnnotation.street = annotation.street;
    if (annotation.dataPopulated) {
        savedAnnotation.info = [NSKeyedArchiver archivedDataWithRootObject:annotation.info];
    }
    
    return savedAnnotation;
}

- (void)bookmarkAnnotation:(ArcGISMapAnnotation *)annotation {
    MapSavedAnnotation *savedAnnotation = [self savedAnnotationWithAnnotation:annotation];
    savedAnnotation.isBookmark = [NSNumber numberWithBool:YES];
    savedAnnotation.sortOrder = [NSNumber numberWithInt:[_bookmarks count]];
    [_bookmarks addObject:savedAnnotation];
    [CoreDataManager saveData];
}

- (void)saveAnnotationWithoutBookmarking:(ArcGISMapAnnotation *)annotation {
    MapSavedAnnotation *savedAnnotation = [self savedAnnotationWithAnnotation:annotation];
    savedAnnotation.isBookmark = [NSNumber numberWithBool:NO];
    [CoreDataManager saveData];
}

- (void)removeBookmark:(MapSavedAnnotation *)savedAnnotation {
    NSInteger sortOrder = [savedAnnotation.sortOrder integerValue];
    // decrement sortOrder of all bookmarks after this
    for (NSInteger i = sortOrder + 1; i < [_bookmarks count]; i++) {
        MapSavedAnnotation *savedAnnotation = [_bookmarks objectAtIndex:i];
        savedAnnotation.sortOrder = [NSNumber numberWithInt:i - 1];
    }
    [_bookmarks removeObject:savedAnnotation];
    [CoreDataManager deleteObject:savedAnnotation];
    [CoreDataManager saveData];
}

- (BOOL)isBookmarked:(NSString *)uniqueID {
    MapSavedAnnotation *saved = [self savedAnnotationForID:uniqueID];
    return (saved != nil && [saved.isBookmark boolValue]);
}

- (void)moveBookmarkFromRow:(int) from toRow:(int)to
{
    if (to != from) {
		MapSavedAnnotation *savedAnnotation = nil;

        // if the row is moving down (from < to), the sortOrder of the
        // moved item increases and everything between decreases by 1
        NSInteger startIndex = (from < to) ? from + 1 : to;
        NSInteger endIndex = (from < to) ? to + 1 : from;
        NSInteger sortOrderDiff = (from < to) ? -1 : 1;
        
        for (NSInteger i = startIndex; i < endIndex; i++) {
            savedAnnotation = [self.bookmarks objectAtIndex:i];
            savedAnnotation.sortOrder = [NSNumber numberWithInt:i + sortOrderDiff];
        }

        savedAnnotation = [self.bookmarks objectAtIndex:from];
        savedAnnotation.sortOrder = [NSNumber numberWithInt:to];
        
        [CoreDataManager saveData];
    }
}

@end
