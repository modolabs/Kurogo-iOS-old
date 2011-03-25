#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"

NSString * const KGOUserPreferencesKey = @"KGOUserPrefs";
NSString * const KGOUserPreferencesDidChangeNotification = @"KGOUserPrefsChanged";

NSString * const KGOAccessoryTypeNone = @"None";
NSString * const KGOAccessoryTypeBlank = @"Blank";
NSString * const KGOAccessoryTypeChevron = @"Chevron";
NSString * const KGOAccessoryTypeCheckmark = @"Check";


@implementation KGOTheme

static KGOTheme *s_sharedTheme = nil;

+ (KGOTheme *)sharedTheme {
    if (s_sharedTheme == nil) {
        s_sharedTheme = [[KGOTheme alloc] init];
    }
    return s_sharedTheme;
}

- (UIFont *)fontForContentTitle {
    return [self matchBoldFontWithLabel:@"ContentTitle" defaultSize:7];
}

- (UIColor *)textColorForContentTitle {
    UIColor *color = [self matchTextColorWithLabel:@"ContentTitle"];
    if (!color)
        color = [UIColor blackColor];
    return color;
}

- (UIFont *)fontForBodyText {
    return [self matchFontWithLabel:@"BodyText" defaultSize:0];
}

- (UIColor *)textColorForBodyText {
    UIColor *color = [self matchTextColorWithLabel:@"BodyText"];
    if (!color)
        color = [UIColor blackColor];
    return color;
}

- (CGFloat)defaultFontSize
{
    CGFloat fontSize = [[fontDict objectForKey:@"DefaultFontSize"] floatValue];
    if (fontSize) {
        return fontSize;
    }
    return [UIFont systemFontSize];
}

#pragma mark Colors

- (UIColor *)linkColor {
    UIColor *color = [self matchBackgroundColorWithLabel:@"Link"];
    if (!color)
        color = [UIColor blueColor];
    return color;
}

- (UIColor *)backgroundColorForApplication {
    UIColor *color = [self matchBackgroundColorWithLabel:@"AppBackground"];
    if (!color)
        color = [UIColor whiteColor];
    return color;
}

// this one can be nil
// TODO: make nil/non-nil distinction more transparent
- (UIColor *)tintColorForSearchBar {
    UIColor *color = [self matchBackgroundColorWithLabel:@"SearchBarTintColor"];
    return color;
}

- (UIColor *)tintColorForNavBar {
    UIColor *color = [self matchBackgroundColorWithLabel:@"NavBarTintColor"];
    return color;
}

- (UIImage *)titleImageForNavBar {
    NSString *imageName = [[themeDict objectForKey:@"Images"] objectForKey:@"NavBarTitle"];
    if (imageName)
        return [UIImage imageWithPathName:imageName];
    return nil;
}

- (UIImage *)backgroundImageForToolbar {
    NSString *imageName = [[themeDict objectForKey:@"Images"] objectForKey:@"ToolbarBackground"];
    if (imageName)
        return [UIImage imageWithPathName:imageName];
    return nil;
}

- (UIImage *)backgroundImageForNavBar {
    NSString *imageName = [[themeDict objectForKey:@"Images"] objectForKey:@"NavBarBackground"];
    if (imageName)
        return [UIImage imageWithPathName:imageName];
    return nil;
}

- (UIImage *)backgroundImageForSearchBar {
    NSString *imageName = [[themeDict objectForKey:@"Images"] objectForKey:@"SearchBarBackground"];
    if (imageName)
        return [UIImage imageWithPathName:imageName];
    return nil;
}

- (UIImage *)backgroundImageForSearchBarDropShadow {
    NSString *imageName = [[themeDict objectForKey:@"Images"] objectForKey:@"SearchBarDropShadow"];
    if (imageName)
        return [UIImage imageWithPathName:imageName];
    return nil;
}

#pragma mark UITableView

- (UIFont *)fontForTableCellTitleWithStyle:(KGOTableCellStyle)style {
    switch (style) {
        case KGOTableCellStyleValue2:
            return [self matchBoldFontWithLabel:@"TableCellValue2Title" defaultSize:-1];
        case KGOTableCellStyleBodyText:
            return [self matchFontWithLabel:@"TableCellTitle" defaultSize:0];
        case KGOTableCellStyleURL:
            return [self matchFontWithLabel:@"TableCellTitle" defaultSize:2];
        default: // default, subtitle, value1
            return [self matchBoldFontWithLabel:@"TableCellTitle" defaultSize:2];
    }
}

- (UIColor *)textColorForTableCellTitleWithStyle:(KGOTableCellStyle)style {
    UIColor *color = nil;
    switch (style) {
        case KGOTableCellStyleValue2:
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
        case KGOTableCellStyleValue1:
            return [self matchFontWithLabel:@"TableCellValue1Subtitle" defaultSize:-2];
        case KGOTableCellStyleValue2:
            return [self matchBoldFontWithLabel:@"TableCellTitle" defaultSize:2];
        default:
            return [self matchFontWithLabel:@"TableCellSubtitle" defaultSize:-2];
    }
}

- (UIColor *)textColorForTableCellSubtitleWithStyle:(KGOTableCellStyle)style {
    UIColor *color = nil;
    
    switch (style) {
        case KGOTableCellStyleValue1:
            color = [self matchTextColorWithLabel:@"TableCellValue1Subtitle"];
            break;
        case KGOTableCellStyleValue2:
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
    return [self matchBoldFontWithLabel:@"GroupedSectionHeader" defaultSize:2];
}

- (UIColor *)textColorForGroupedSectionHeader {
    UIColor *color = [self matchTextColorWithLabel:@"GroupedSectionHeader"];
    if (!color)
        color = [UIColor grayColor];
    return color;
}

- (UIFont *)fontForPlainSectionHeader {
    return [self matchBoldFontWithLabel:@"PlainSectionHeader" defaultSize:0];
}

- (UIColor *)textColorForPlainSectionHeader {
    UIColor *color = [self matchTextColorWithLabel:@"PlainSectionHeader"];
    if (!color)
        color = [UIColor grayColor];
    return color;
}

- (UIColor *)backgroundColorForPlainSectionHeader {
    UIColor *color = [self matchBackgroundColorWithLabel:@"PlainSectionHeaderBackground"];
    if (!color)
        color = [UIColor blackColor];
    return color;
}

- (UIFont *)fontForTableFooter {
    return [self matchBoldFontWithLabel:@"TableFooter" defaultSize:-3];
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
static NSString * KGOAccessoryImageCheckmark = @"common/action-checkmark.png";
static NSString * KGOAccessoryImageCheckmarkHighlighted = @"common/action-checkmark-highlighted.png";

// provide None, Blank, and Chevron by default.
// other styles can be defined in theme plist
- (UIImageView *)accessoryViewForType:(NSString *)accessoryType {
    if (!accessoryType || [accessoryType isEqualToString:KGOAccessoryTypeNone]) {

        return nil;

    } else if ([accessoryType isEqualToString:KGOAccessoryTypeBlank]) {
    
        UIImage *image = [UIImage imageWithPathName:KGOAccessoryImageBlank];
        return [[[UIImageView alloc] initWithImage:image] autorelease];
        
    } else if ([accessoryType isEqualToString:KGOAccessoryTypeChevron]) {

        UIImage *image = [UIImage imageWithPathName:KGOAccessoryImageChevron];
        UIImage *highlightedImage = [UIImage imageWithPathName:KGOAccessoryImageChevronHighlighted];
        return [[[UIImageView alloc] initWithImage:image highlightedImage:highlightedImage] autorelease];
    
    } else if ([accessoryType isEqualToString:KGOAccessoryTypeCheckmark]) {
        
        UIImage *image = [UIImage imageWithPathName:KGOAccessoryImageCheckmark];
        UIImage *highlightedImage = [UIImage imageWithPathName:KGOAccessoryImageCheckmarkHighlighted];
        return [[[UIImageView alloc] initWithImage:image highlightedImage:highlightedImage] autorelease];
        
    } else {

        NSDictionary *actionDict = [[themeDict objectForKey:@"TableViewCellActions"] objectForKey:accessoryType];
        NSString *imageName = [NSString stringWithFormat:@"common/%@.png", [actionDict objectForKey:@"image"]];
        NSString *highlightedName = [NSString stringWithFormat:@"common/%@.png", [actionDict objectForKey:@"highlightedImage"]];

        UIImage *image = [UIImage imageWithPathName:imageName];
        UIImage *highlightedImage = [UIImage imageWithPathName:highlightedName];
        
        return [[[UIImageView alloc] initWithImage:image highlightedImage:highlightedImage] autorelease];
    }    
}

- (UIColor *)backgroundColorForSecondaryCell {
    UIColor *color = [self matchTextColorWithLabel:@"SecondaryCellBackground"];
    if (!color)
        color = [UIColor whiteColor];
    return color;
}

#pragma mark -

- (NSString *)fontNameForLabel:(NSString *)label size:(CGFloat *)fontSize {
    NSDictionary *fontInfo = [fontDict objectForKey:label];
    NSString *fontName = nil;
    if (fontInfo) {
        NSNumber *newFontSize = [themeDict objectForKey:@"size"];
        if (newFontSize) {
            *fontSize = [newFontSize floatValue];
        }
        fontName = [themeDict objectForKey:@"font"];
    }
    return fontName;
}

- (UIFont *)matchFontWithLabel:(NSString *)label defaultSize:(CGFloat)defaultSize {
    CGFloat fontSize = [self defaultFontSize];
    CGFloat fontOffset = defaultSize;
    NSString *fontName = [self fontNameForLabel:label size:&fontOffset];
    fontSize += fontOffset;
    if (!fontName)
        fontName = [fontDict objectForKey:@"DefaultFont"];
    if (fontName)
        return [UIFont fontWithName:fontName size:fontSize];
    return [UIFont systemFontOfSize:fontSize];
}

- (UIFont *)matchBoldFontWithLabel:(NSString *)label defaultSize:(CGFloat)defaultSize {
    CGFloat fontSize = [self defaultFontSize];
    CGFloat fontOffset = defaultSize;
    NSString *fontName = [self fontNameForLabel:label size:&fontOffset];
    fontSize += fontOffset;
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

- (UIColor *)matchBackgroundColorWithLabel:(NSString *)label {
    UIColor *color = nil;
    NSString *colorString = [[themeDict objectForKey:@"Colors"] objectForKey:label];
    if (colorString) {
        // check if there is a valid image first
        UIImage *image = [UIImage imageWithPathName:colorString];
        if (image) {
            // TODO: if we get to this point we need to make sure iphone/ipad resources are distinguished
            color = [UIColor colorWithPatternImage:image];
        } else {
            color = [UIColor colorWithHexString:colorString];
        }
    }
    return color;
}

#pragma mark - Private

- (void)loadFontPreferences
{
    NSMutableDictionary *mutableFontDict = [[themeDict objectForKey:@"Fonts"] mutableCopy];
    NSDictionary *userSettings = [[NSUserDefaults standardUserDefaults] objectForKey:KGOUserPreferencesKey];
    if (userSettings) {
        // TODO: reduce the hard-coded ness of our settings overrides
        CGFloat fontSize = [[mutableFontDict objectForKey:@"DefaultFontSize"] floatValue];
        if (!fontSize) {
            fontSize = [UIFont systemFontSize];
        }

        NSString *fontSizePref = [userSettings objectForKey:@"DefaultFontSize"];
        if ([fontSizePref isEqualToString:@"Tiny"]) {
            fontSize -= 2;
        } else if ([fontSizePref isEqualToString:@"Small"]) {
            fontSize -= 1;
        } else if ([fontSizePref isEqualToString:@"Large"]) {
            fontSize += 1;
        } else if ([fontSizePref isEqualToString:@"Huge"]) {
            fontSize += 2;
        }
        [mutableFontDict setObject:[NSNumber numberWithFloat:fontSize] forKey:@"DefaultFontSize"];
        
        NSString *fontPref = [userSettings objectForKey:@"DefaultFont"];
        if (fontPref) {
            UIFont *font = [UIFont fontWithName:fontPref size:fontSize];
            if (font) {
                [mutableFontDict setObject:fontPref forKey:@"DefaultFont"];
            }
            NSString *boldFontPref = [NSString stringWithFormat:@"%@-Bold", fontPref];
            font = [UIFont fontWithName:boldFontPref size:fontSize];
            if (font) {
                [mutableFontDict setObject:boldFontPref forKey:@"DefaultBoldFont"];
            }
        }
    }
    fontDict = [mutableFontDict copy];
}

- (void)userDefaultsDidChange:(NSNotification *)aNotification
{
    [self loadFontPreferences];
}

#pragma mark -

- (id)init {
    self = [super init];
    if (self) {
		NSString * file = [[NSBundle mainBundle] pathForResource:@"ThemeConfig" ofType:@"plist"];
        themeDict = [[NSDictionary alloc] initWithContentsOfFile:file];
        [self loadFontPreferences];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userDefaultsDidChange:)
                                                     name:KGOUserPreferencesDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
	fontDict = nil;
    [themeDict release];
    [super dealloc];
}

@end
