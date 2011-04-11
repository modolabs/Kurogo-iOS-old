#import <UIKit/UIKit.h>

extern NSString * const KGOUserPreferencesKey;
extern NSString * const KGOUserPreferencesDidChangeNotification;

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
extern NSString * const KGOThemePropertyNavListTitle;
extern NSString * const KGOThemePropertyNavListSubtitle;
extern NSString * const KGOThemePropertyNavListLabel;
extern NSString * const KGOThemePropertyNavListValue;
extern NSString * const KGOThemePropertySectionHeader;
extern NSString * const KGOThemePropertySectionHeaderGrouped;
extern NSString * const KGOThemePropertyTab;
extern NSString * const KGOThemePropertyTabSelected;

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

#pragma mark generic

- (UIFont *)defaultFont;
- (UIFont *)defaultBoldFont;
- (CGFloat)defaultFontSize;
- (NSString *)defaultFontName;
- (UIFont *)fontForThemedProperty:(NSString *)themeProperty;
- (UIColor *)textColorForThemedProperty:(NSString *)themeProperty;

- (UIColor *)backgroundColorForApplication;
- (UIColor *)linkColor;
- (UIColor *)tintColorForToolbar;
- (UIColor *)tintColorForSearchBar;
- (UIColor *)tintColorForNavBar;
- (UIImage *)titleImageForNavBar;

// reasonable overrides

- (UIImage *)backgroundImageForToolbar;

// ridiculous overrides

- (UIImage *)backgroundImageForNavBar;
- (UIImage *)backgroundImageForSearchBar;
- (UIImage *)backgroundImageForSearchBarDropShadow;

#pragma mark homescreen

- (NSDictionary *)homescreenConfig;

#pragma mark tableview

- (UIColor *)backgroundColorForPlainSectionHeader;

#pragma mark tableviewcell

- (UIImageView *)accessoryViewForType:(NSString *)accessoryType;
- (UIColor *)backgroundColorForSecondaryCell;

@end
