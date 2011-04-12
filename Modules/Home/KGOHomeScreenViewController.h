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

// login states
- (void)standbyForServerHello;
- (void)helloRequestDidComplete:(NSNotification *)aNotification;
- (void)loginDidComplete:(NSNotification *)aNotification;
- (void)logoutDidComplete:(NSNotification *)aNotification;
- (void)showLoadingView;
- (void)hideLoadingView;

// springboard helpers
- (NSArray *)iconsForPrimaryModules:(BOOL)isPrimary;
- (NSArray *)allWidgets:(CGFloat *)topFreePixel :(CGFloat *)bottomFreePixel;


- (void)showSettingsModule:(id)sender;

// display module representations on home screen. default implementation does nothing.
- (void)refreshModules;

// display widgets on home screen. default implementation does nothing.
- (void)refreshWidgets;

- (CGSize)moduleLabelMaxDimensions;
- (CGSize)secondaryModuleLabelMaxDimensions;

// properties defined in ThemeConfig.plist
- (BOOL)showsSearchBar;           // true to show search bar on home screen.  default is NO.
- (BOOL)showsSettingsInNavBar;    // true to show settings button in top right.  default is NO.
- (UIColor *)backgroundColor;     // home screen background color or image

- (UIFont *)moduleLabelFont;
- (UIFont *)moduleLabelFontLarge;
- (UIColor *)moduleLabelTextColor;
- (CGFloat)moduleLabelTitleMargin; // spacing between image and title
- (GridSpacing)moduleListSpacing;  // spacing between icons or list elements
- (GridPadding)moduleListMargins;  // margins around entire grid/list
- (CGSize)moduleIconSize;

- (UIFont *)secondaryModuleLabelFont;
- (UIColor *)secondaryModuleLabelTextColor;
- (GridSpacing)secondaryModuleListSpacing;
- (GridPadding)secondaryModuleListMargins;
- (CGFloat)secondaryModuleLabelTitleMargin;
- (CGSize)secondaryModuleIconSize;

@end
