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

@property (nonatomic, retain) KGOModule *homeModule;

@property (nonatomic, readonly) NSArray *primaryModules;
@property (nonatomic, readonly) NSArray *secondaryModules;
@property (nonatomic, readonly) CGRect springboardFrame;
@property (nonatomic, retain) UIView *loadingView;

- (void)showLoadingView;
- (void)hideLoadingView;

- (NSArray *)iconsForPrimaryModules:(BOOL)isPrimary;

- (NSArray *)allWidgets:(CGFloat *)topFreePixel :(CGFloat *)bottomFreePixel;

// display module representations on home screen. default implementation does nothing.
- (void)refreshModules;

// display widgets on home screen. default implementation does nothing.
- (void)refreshWidgets;

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
