#import <UIKit/UIKit.h>

extern NSString * const KGOAccessoryTypeNone;
extern NSString * const KGOAccessoryTypeBlank;
extern NSString * const KGOAccessoryTypeChevron;

typedef enum {
	KGOTableCellStyleDefault = UITableViewCellStyleDefault,
	KGOTableCellStyleSubtitle = UITableViewCellStyleSubtitle,
	KGOTableCellStyleValue1 = UITableViewCellStyleValue1,
	KGOTableCellStyleValue2 = UITableViewCellStyleValue2,
	KGOTableCellStyleBodyText,
	KGOTableCellStyleURL
} KGOTableCellStyle;

@interface KGOTheme : NSObject {
    
    NSDictionary *themeDict;
	NSDictionary *fontDict;

}

+ (KGOTheme *)sharedTheme;
- (UIFont *)fontForContentTitle;
- (UIColor *)textColorForContentTitle;
- (UIFont *)fontForBodyText;
- (UIColor *)textColorForBodyText;
- (UIColor *)linkColor;

- (UIFont *)fontForTableCellTitleWithStyle:(KGOTableCellStyle)style;
- (UIColor *)textColorForTableCellTitleWithStyle:(KGOTableCellStyle)style;
- (UIFont *)fontForTableCellSubtitleWithStyle:(KGOTableCellStyle)style;
- (UIColor *)textColorForTableCellSubtitleWithStyle:(KGOTableCellStyle)style;
- (UIFont *)fontForGroupedSectionHeader;
- (UIColor *)textColorForGroupedSectionHeader;
- (UIFont *)fontForPlainSectionHeader;
- (UIColor *)textColorForPlainSectionHeader;
- (UIColor *)plainSectionHeaderBackgroundColor;
- (UIFont *)fontForTableFooter;
- (UIColor *)textColorForTableFooter;

- (UIImageView *)accessoryViewForType:(NSString *)accessoryType;

@end
