#import <UIKit/UIKit.h>
#import "KGOSearchDisplayController.h"
#import "IconGrid.h"
#import "KGOAppDelegate+ModuleAdditions.h"

@class KGOSearchBar;

@interface KGOHomeScreenViewController : UIViewController <KGOSearchDisplayDelegate> {
    
    NSDictionary *_preferences;
    
    KGOSearchBar *_searchBar;
    KGOSearchDisplayController *_searchController;
    
    NSArray *_primaryModules;
    NSArray *_secondaryModules;
}

@property (nonatomic, readonly) NSArray *primaryModules;
@property (nonatomic, readonly) NSArray *secondaryModules;

- (NSArray *)iconsForPrimaryModules:(BOOL)isPrimary;

- (CGSize)moduleLabelMaxDimensions;
- (CGSize)secondaryModuleLabelMaxDimensions;

// properties defined in Theme.plist
- (BOOL)showsSearchBar;                     // true to show search bar on home screen
- (UIImage *)backgroundImage;               // home screen background image
- (UIFont *)moduleLabelFont;
- (UIFont *)moduleLabelFontLarge;
- (UIColor *)moduleLabelTextColor;
- (CGFloat)moduleLabelTitleMargin;          // spacing between image and title
- (GridSpacing)moduleListSpacing;           // spacing between icons or list elements
- (GridPadding)moduleListMargins;           // margins around entire grid/list
- (UIFont *)secondaryModuleLabelFont;
- (UIColor *)secondaryModuleLabelTextColor;
- (GridSpacing)secondaryModuleListSpacing;
- (GridPadding)secondaryModuleListMargins;
- (CGFloat)secondaryModuleLabelTitleMargin;

@end
