#import <UIKit/UIKit.h>

extern NSString * const KGOAccessoryTypeNone;
extern NSString * const KGOAccessoryTypeBlank;
extern NSString * const KGOAccessoryTypeCheckmark;
extern NSString * const KGOAccessoryTypeChevron;
extern NSString * const KGOAccessoryTypePhone;
extern NSString * const KGOAccessoryTypePeople;
extern NSString * const KGOAccessoryTypeMap;
extern NSString * const KGOAccessoryTypeEmail;
extern NSString * const KGOAccessoryTypeExternal;

extern NSString * const KGOThemePropertyBodyText;
extern NSString * const KGOThemePropertySmallPrint;
extern NSString * const KGOThemePropertyContentTitle;
extern NSString * const KGOThemePropertyContentSubtitle;
extern NSString * const KGOFontPageTitle;
extern NSString * const KGOThemePropertyPageSubtitle;
extern NSString * const KGOThemePropertyCaption;
extern NSString * const KGOThemePropertyByline;
extern NSString * const KGOThemePropertyMediaListTitle;
extern NSString * const KGOThemePropertyMediaListSubtitle;
extern NSString * const KGOThemePropertyNavListTitle;
extern NSString * const KGOThemePropertyNavListSubtitle;
extern NSString * const KGOThemePropertyNavListLabel;
extern NSString * const KGOThemePropertyNavListValue;
extern NSString * const KGOThemePropertyScrollTab;
extern NSString * const KGOThemePropertyScrollTabSelected;
extern NSString * const KGOThemePropertySectionHeader;
extern NSString * const KGOThemePropertySectionHeaderGrouped;
extern NSString * const KGOThemePropertyTab;
extern NSString * const KGOThemePropertyTabSelected; // pressed state
extern NSString * const KGOThemePropertyTabActive;

typedef enum {
	KGOTableCellStyleDefault,
	KGOTableCellStyleValue1,
	KGOTableCellStyleValue2,
	KGOTableCellStyleSubtitle,
	KGOTableCellStyleBodyText,
	KGOTableCellStyleURL
} KGOTableCellStyle;


@interface KGOTheme : NSObject {
    
    NSDictionary *themeDict;
	NSDictionary *fontDict;
}

+ (KGOTheme *)sharedTheme;

#pragma mark Fonts and text attributes

- (UIFont *)defaultFont;
- (UIFont *)defaultBoldFont;
- (CGFloat)defaultFontSize;
- (NSString *)defaultFontName;
- (UIFont *)fontForThemedProperty:(NSString *)themeProperty;
- (UIColor *)textColorForThemedProperty:(NSString *)themeProperty;

#pragma mark - Universal colors

- (UIColor *)backgroundColorForApplication;
- (UIColor *)linkColor;

#pragma mark View colors

- (UIColor *)tintColorForToolbar;
- (UIColor *)tintColorForSearchBar;
- (UIColor *)tintColorForNavBar;
- (UIColor *)backgroundColorForDatePager;

#pragma mark Table view colors

- (UIColor *)tintColorForSelectedCell;
- (UIColor *)tableSeparatorColor;
- (UIColor *)backgroundColorForPlainSectionHeader;

#pragma mark - Background images

- (UIImage *)backgroundImageForToolbar;
- (UIImage *)backgroundImageForSearchBar;
- (UIImage *)backgroundImageForSearchBarDropShadow;
- (UIImage *)backgroundImageForNavBar;

#pragma mark Foreground images

- (UIImage *)titleImageForNavBar;

#pragma mark - Enumerated styles

- (UIBarStyle)defaultNavBarStyle;

#pragma mark - Homescreen

- (NSDictionary *)homescreenConfig;

#pragma mark - Table view cell

- (UIImageView *)accessoryViewForType:(NSString *)accessoryType;
- (UIColor *)backgroundColorForSecondaryCell;

@end
