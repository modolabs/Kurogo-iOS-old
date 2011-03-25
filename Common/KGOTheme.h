#import <UIKit/UIKit.h>

extern NSString * const KGOUserPreferencesKey;
extern NSString * const KGOUserPreferencesDidChangeNotification;

extern NSString * const KGOAccessoryTypeNone;
extern NSString * const KGOAccessoryTypeBlank;
extern NSString * const KGOAccessoryTypeCheckmark;
extern NSString * const KGOAccessoryTypeChevron;

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

#pragma mark custom properties

- (NSString *)fontNameForLabel:(NSString *)label size:(CGFloat *)fontSize;
- (UIColor *)matchTextColorWithLabel:(NSString *)label;
- (UIFont *)matchFontWithLabel:(NSString *)label defaultSize:(CGFloat)defaultSize;
- (UIFont *)matchBoldFontWithLabel:(NSString *)label defaultSize:(CGFloat)defaultSize;
- (UIColor *)matchBackgroundColorWithLabel:(NSString *)label;

#pragma mark generic

- (UIFont *)defaultFont;
- (UIFont *)defaultBoldFont;
- (UIFont *)defaultSmallFont;
- (UIFont *)defaultSmallBoldFont;

- (UIFont *)fontForContentTitle;
- (UIColor *)textColorForContentTitle;
- (UIFont *)fontForBodyText;
- (UIColor *)textColorForBodyText;
- (CGFloat)defaultFontSize;

- (UIColor *)backgroundColorForApplication;
- (UIColor *)linkColor;
- (UIColor *)tintColorForSearchBar;
- (UIColor *)tintColorForNavBar;
- (UIImage *)titleImageForNavBar;

// reasonable overrides

- (UIImage *)backgroundImageForToolbar;

// ridiculous overrides

- (UIImage *)backgroundImageForNavBar;
- (UIImage *)backgroundImageForSearchBar;
- (UIImage *)backgroundImageForSearchBarDropShadow;

#pragma mark tableview

- (UIFont *)fontForTableCellTitleWithStyle:(KGOTableCellStyle)style;
- (UIColor *)textColorForTableCellTitleWithStyle:(KGOTableCellStyle)style;
- (UIFont *)fontForTableCellSubtitleWithStyle:(KGOTableCellStyle)style;
- (UIColor *)textColorForTableCellSubtitleWithStyle:(KGOTableCellStyle)style;
- (UIFont *)fontForGroupedSectionHeader;
- (UIColor *)textColorForGroupedSectionHeader;
- (UIFont *)fontForPlainSectionHeader;
- (UIColor *)textColorForPlainSectionHeader;
- (UIColor *)backgroundColorForPlainSectionHeader;
- (UIFont *)fontForTableFooter;
- (UIColor *)textColorForTableFooter;

#pragma mark tableviewcell

- (UIImageView *)accessoryViewForType:(NSString *)accessoryType;
- (UIColor *)backgroundColorForSecondaryCell;

@end
