#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@protocol KGOSearchResult <NSObject>

- (NSString *)resultTitle;

@optional

- (NSString *)resultSubtitle;

- (NSArray *)viewsForTableCell; // how to be displayed in a search results or bookmarks table view

- (UIImage *)annotationImage;   // image to use in map view (and maybe table view)
- (CLLocation *)coordinate;     // location of item if any

@end
