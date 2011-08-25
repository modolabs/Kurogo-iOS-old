#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"

@protocol KGOSearchResult <NSObject>

- (NSString *)identifier;
- (NSString *)title;

- (BOOL)isBookmarked;
- (void)addBookmark;
- (void)removeBookmark;

@optional

- (NSString *)moduleTag;
- (NSString *)subtitle;
- (NSArray *)viewsForTableCell; // how to be displayed in a search results or bookmarks table view
- (UIImage *)annotationImage;   // image to use in map view (and maybe table view)

// not sure whether to use this yet
// it looks like it could take some code out of table view controllers
- (CellManipulator)manipulatorForContext:(id)context;

@end

#pragma mark -

@protocol KGOCategory <NSObject>

- (NSString *)identifier;
- (NSString *)title;
- (id<KGOCategory>)parent; // nil if this is top level category.
- (NSArray *)children;     // an array of id<KGOCategory> objects. may be nil.
- (NSArray *)items;        // an array of id<KGOSearchResult> objects. may be nil.

@optional

- (NSString *)moduleTag;

// ditto above
- (CellManipulator)manipulatorForContext:(id)context;

@end

#pragma mark -

@protocol KGOSearchResultsHolder <NSObject>

- (void)searcher:(id)searcher didReceiveResults:(NSArray *)results;

@end
