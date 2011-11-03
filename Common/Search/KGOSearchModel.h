#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"
#import "KGOTheme.h"

@protocol KGOListItem <NSObject>

- (NSString *)identifier;
- (NSString *)title;

@optional

- (NSString *)subtitle;

@end

#pragma mark -

@protocol KGOSearchResult <KGOListItem>

- (BOOL)isBookmarked;
- (void)addBookmark;
- (void)removeBookmark;

- (ModuleTag *)moduleTag;

@optional

- (NSString *)subtitle;
- (NSArray *)viewsForTableCell;   // how to be displayed in a search results or bookmarks table view

- (UIImage *)annotationImage;     // image to use in map view
- (UIImage *)tableCellThumbImage; // image to use in table view
- (NSString *)accessoryType;

- (BOOL)didGetSelected:(id)selector;

@end

#pragma mark -

@protocol KGOCategory <KGOListItem>

- (id<KGOCategory>)parent; // nil if this is top level category.
- (NSArray *)children;     // an array of id<KGOCategory> objects. may be nil.
- (NSArray *)items;        // an array of id<KGOSearchResult> objects. may be nil.

@optional

- (ModuleTag *)moduleTag;

@end

#pragma mark -

@protocol KGOSearchResultsHolder <NSObject>

- (void)receivedSearchResults:(NSArray *)results forSource:(ModuleTag *)source;
- (NSArray *)results;

@end
