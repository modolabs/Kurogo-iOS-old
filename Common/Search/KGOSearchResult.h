#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "KGOTableViewController.h"

@protocol KGOSearchResult <NSObject>

- (NSString *)title;

@optional

- (NSString *)subtitle;
- (NSArray *)viewsForTableCell; // how to be displayed in a search results or bookmarks table view
- (UIImage *)annotationImage;   // image to use in map view (and maybe table view)

// not sure whether to use this yet
// it looks like it could take some code out of table view controllers
- (CellManipulator)manipulatorForContext:(id)context;

@end


@protocol KGOCategory <NSObject>

- (NSString *)title;
- (id<KGOCategory>)parent;
- (NSArray *)children; // an array of id<KGOCategory> objects. may be nil.
- (NSArray *)items;    // an array of id<KGOSearchResult> objects. may be nil.

@optional

// ditto above
- (CellManipulator)manipulatorForContext:(id)context;

@end
