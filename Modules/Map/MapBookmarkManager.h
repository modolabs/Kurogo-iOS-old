#import <Foundation/Foundation.h>
#import "MapSearchResultAnnotation.h"
#import "KGOPlacemark.h"

@interface MapBookmarkManager : NSObject {
	NSMutableArray* _bookmarks;
}

@property (nonatomic, retain) NSMutableArray *bookmarks;

+ (MapBookmarkManager *)defaultManager;

- (KGOPlacemark *)savedAnnotationForID:(NSString *)uniqueID;
- (void)pruneNonBookmarks;

- (void)bookmarkAnnotation:(ArcGISMapAnnotation *)annotation;
- (void)saveAnnotationWithoutBookmarking:(ArcGISMapAnnotation *)annotation;
- (void)removeBookmark:(KGOPlacemark *)savedAnnotation;
- (BOOL)isBookmarked:(NSString *)uniqueID;

- (void)moveBookmarkFromRow:(int)from toRow:(int)to;

@end
