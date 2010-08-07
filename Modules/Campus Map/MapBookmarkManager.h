#import <Foundation/Foundation.h>
#import "MapSearchResultAnnotation.h"
#import "MapSavedAnnotation.h"

@interface MapBookmarkManager : NSObject {
	NSMutableArray* _bookmarks;
}

@property (nonatomic, retain) NSArray *bookmarks;

+ (MapBookmarkManager *)defaultManager;

- (MapSavedAnnotation *)savedAnnotationForID:(NSString *)uniqueID;

- (void)bookmarkAnnotation:(ArcGISMapSearchResultAnnotation *)annotation;
- (void)saveAnnotationWithoutBookmarking:(ArcGISMapSearchResultAnnotation *)annotation;
- (void)removeBookmark:(MapSavedAnnotation *)savedAnnotation;
- (BOOL)isBookmarked:(NSString *)uniqueID;

- (void)moveBookmarkFromRow:(int)from toRow:(int)to;

@end
