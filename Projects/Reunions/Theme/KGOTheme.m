#import "KGOTheme.h"
#import "UIKit+MITAdditions.h"

NSString * const KGOAccessoryTypeNone = @"None";
NSString * const KGOAccessoryTypeBlank = @"Blank";
NSString * const KGOAccessoryTypeChevron = @"Chevron";

@interface KGOTheme (Private)

- (NSString *)fontNameForLabel:(NSString *)label size:(CGFloat *)fontSize;
- (UIColor *)matchTextColorWithLabel:(NSString *)label;
- (UIFont *)matchFontWithLabel:(NSString *)label defaultSize:(CGFloat)defaultSize;
- (UIFont *)matchBoldFontWithLabel:(NSString *)label defaultSize:(CGFloat)defaultSize;

@end


@implementation KGOTheme

static KGOTheme *s_sharedTheme = nil;

+ (KGOTheme *)sharedTheme {
    if (s_sharedTheme == nil) {
        s_sharedTheme = [[KGOTheme alloc] init];
    }
    return s_sharedTheme;
}

- (UIFont *)fontForContentTitle {
    return [self matchBoldFontWithLabel:@"ContentTitle" defaultSize:22];
}

- (UIColor *)textColorForContentTitle {
    UIColor *color = [self matchTextColorWithLabel:@"ContentTitle"];
    if (!color)
        color = [UIColor blackColor];
    return color;
}

- (UIFont *)fontForBodyText {
    return [self matchFontWithLabel:@"BodyText" defaultSize:15];
}

- (UIColor *)textColorForBodyText {
    UIColor *color = [self matchTextColorWithLabel:@"BodyText"];
    if (!color)
        color = [UIColor blackColor];
    return color;
}

#pragma mark Colors

- (UIColor *)linkColor {
    NSString *hexString = [[themeDict objectForKey:@"Colors"] objectForKey:@"Link"];
    if (hexString)
        return [UIColor colorWithHexString:hexString];
    return [UIColor blueColor];
}

- (UIColor *)plainSectionHeaderBackgroundColor {
    NSString *hexString = [[themeDict objectForKey:@"Colors"] objectForKey:@"PlainSectionHeaderBackground"];
    if (hexString)
        return [UIColor colorWithHexString:hexString];
    return [UIColor blackColor];
}

#pragma mark UITableView

- (UIFont *)fontForTableCellTitleWithStyle:(KGOTableCellStyle)style {
    switch (style) {
        case KGOTableCellStyleValue2:
            return [self matchBoldFontWithLabel:@"TableCellValue2Title" defaultSize:15];
        case KGOTableCellStyleBodyText:
            return [self matchFontWithLabel:@"TableCellTitle" defaultSize:15];
        case KGOTableCellStyleURL:
            return [self matchFontWithLabel:@"TableCellTitle" defaultSize:17];
        default: // default, subtitle, value1
            return [self matchBoldFontWithLabel:@"TableCellTitle" defaultSize:17];
    }
}

- (UIColor *)textColorForTableCellTitleWithStyle:(KGOTableCellStyle)style {
    UIColor *color = nil;
    switch (style) {
        case UITableViewCellStyleValue2:
            color = [self matchTextColorWithLabel:@"TableCellValue2Title"];
            break;
        default:
            color = [self matchTextColorWithLabel:@"TableCellTitle"];
            break;
    }
    if (!color) {
		NSLog(@"no color configured for table cell style %d", style);
        color = [UIColor blackColor];
	}
    return color;
}

- (UIFont *)fontForTableCellSubtitleWithStyle:(KGOTableCellStyle)style {
    switch (style) {
        case UITableViewCellStyleValue1:
            return [self matchFontWithLabel:@"TableCellValue1Subtitle" defaultSize:13];
        case UITableViewCellStyleValue2:
            return [self matchBoldFontWithLabel:@"TableCellTitle" defaultSize:17];
        default:
            return [self matchFontWithLabel:@"TableCellSubtitle" defaultSize:13];
    }
}

- (UIColor *)textColorForTableCellSubtitleWithStyle:(KGOTableCellStyle)style {
    UIColor *color = nil;
    
    switch (style) {
        case UITableViewCellStyleValue1:
            color = [self matchTextColorWithLabel:@"TableCellValue1Subtitle"];
            break;
        case UITableViewCellStyleValue2:
            color = [self matchTextColorWithLabel:@"TableCellValue2Subitle"];
            break;
        default:
            color = [self matchTextColorWithLabel:@"TableCellSubtitle"];
            break;
    }
    if (!color) {
		NSLog(@"no color configured for table cell style %d", style);
        color = [UIColor blackColor];
	}
    return color;
}

- (UIFont *)fontForGroupedSectionHeader {
    return [self matchBoldFontWithLabel:@"GroupedSectionHeader" defaultSize:17];
}

- (UIColor *)textColorForGroupedSectionHeader {
    UIColor *color = [self matchTextColorWithLabel:@"GroupedSectionHeader"];
    if (!color)
        color = [UIColor grayColor];
    return color;
}

- (UIFont *)fontForPlainSectionHeader {
    return [self matchBoldFontWithLabel:@"PlainSectionHeader" defaultSize:15];
}

- (UIColor *)textColorForPlainSectionHeader {
    UIColor *color = [self matchTextColorWithLabel:@"PlainSectionHeader"];
    if (!color)
        color = [UIColor grayColor];
    return color;
}

- (UIFont *)fontForTableFooter {
    return [self matchBoldFontWithLabel:@"TableFooter" defaultSize:12];
}

- (UIColor *)textColorForTableFooter {
    UIColor *color = [self matchTextColorWithLabel:@"TableFooter"];
    if (!color)
        color = [UIColor grayColor];
    return color;
}

#pragma mark UITableViewCell

static NSString * KGOAccessoryImageBlank = @"common/action-blank.png";
static NSString * KGOAccessoryImageChevron = @"common/action-arrow.png";
static NSString * KGOAccessoryImageChevronHighlighted = @"common/action-arrow-highlighted.png";

// provide None, Blank, and Chevron by default.
// other styles can be defined in theme plist
- (UIImageView *)accessoryViewForType:(NSString *)accessoryType {
    if (!accessoryType || [accessoryType isEqualToString:KGOAccessoryTypeNone]) {

        return nil;

    } else if ([accessoryType isEqualToString:KGOAccessoryTypeBlank]) {
    
        UIImage *image = [UIImage imageNamed:KGOAccessoryImageBlank];
        return [[[UIImageView alloc] initWithImage:image] autorelease];
        
    } else if ([accessoryType isEqualToString:KGOAccessoryTypeChevron]) {

        UIImage *image = [UIImage imageNamed:KGOAccessoryImageChevron];
        UIImage *highlightedImage = [UIImage imageNamed:KGOAccessoryImageChevronHighlighted];
        return [[[UIImageView alloc] initWithImage:image highlightedImage:highlightedImage] autorelease];
    
    } else {

        NSDictionary *actionDict = [[themeDict objectForKey:@"TableViewCellActions"] objectForKey:accessoryType];
        NSString *imageName = [NSString stringWithFormat:@"common/%@.png", [actionDict objectForKey:@"image"]];
        NSString *highlightedName = [NSString stringWithFormat:@"common/%@.png", [actionDict objectForKey:@"highlightedImage"]];

        UIImage *image = [UIImage imageNamed:imageName];
        UIImage *highlightedImage = [UIImage imageNamed:highlightedName];
        
        return [[[UIImageView alloc] initWithImage:image highlightedImage:highlightedImage] autorelease];
    }    
}

#pragma mark -
#pragma mark Private

- (NSString *)fontNameForLabel:(NSString *)label size:(CGFloat *)fontSize {
    NSDictionary *fontInfo = [fontDict objectForKey:label];
    NSString *fontName = nil;
    if (fontInfo) {
        CGFloat newFontSize = [[themeDict objectForKey:@"size"] floatValue];
        if (newFontSize)
            *fontSize = newFontSize;
        fontName = [themeDict objectForKey:@"font"];
    }
    return fontName;
}

- (UIFont *)matchFontWithLabel:(NSString *)label defaultSize:(CGFloat)defaultSize {
    CGFloat fontSize = defaultSize;
    NSString *fontName = [self fontNameForLabel:label size:&fontSize];
    if (!fontName)
        fontName = [fontDict objectForKey:@"DefaultFont"];
    if (fontName)
        return [UIFont fontWithName:fontName size:fontSize];
    return [UIFont systemFontOfSize:fontSize];
}

- (UIFont *)matchBoldFontWithLabel:(NSString *)label defaultSize:(CGFloat)defaultSize {
    CGFloat fontSize = defaultSize;
    NSString *fontName = [self fontNameForLabel:label size:&fontSize];
    if (!fontName)
        fontName = [fontDict objectForKey:@"DefaultBoldFont"];
    if (fontName)
        return [UIFont fontWithName:fontName size:fontSize];
    return [UIFont boldSystemFontOfSize:fontSize];
}

- (UIColor *)matchTextColorWithLabel:(NSString *)label {
    NSString *hexString = [[fontDict objectForKey:label] objectForKey:@"color"];
    if (hexString)
        return [UIColor colorWithHexString:hexString];
    return nil;
}

#pragma mark -

- (id)init {
    if (self = [super init]) {
		NSString * file = [[NSBundle mainBundle] pathForResource:@"DefaultTheme" ofType:@"plist"];
        themeDict = [[NSDictionary alloc] initWithContentsOfFile:file];
		fontDict = [themeDict objectForKey:@"Fonts"];
    }
    return self;
}

- (void)dealloc {
	fontDict = nil;
    [themeDict release];
    [super dealloc];
}

@end
