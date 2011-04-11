
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"
#import "Foundation+KGOAdditions.h"

NSString * const KGOUserPreferencesKey = @"KGOUserPrefs";
NSString * const KGOUserPreferencesDidChangeNotification = @"KGOUserPrefsChanged";

NSString * const KGOAccessoryTypeNone = @"None";
NSString * const KGOAccessoryTypeBlank = @"Blank";
NSString * const KGOAccessoryTypeChevron = @"Chevron";
NSString * const KGOAccessoryTypeCheckmark = @"Check";
NSString * const KGOAccessoryTypePhone = @"Phone";
NSString * const KGOAccessoryTypePeople = @"People";
NSString * const KGOAccessoryTypeMap = @"Map";
NSString * const KGOAccessoryTypeEmail = @"Email";
NSString * const KGOAccessoryTypeExternal = @"External";


NSString * const KGOThemePropertyBodyText = @"BodyText";
NSString * const KGOThemePropertySmallPrint = @"SmallPrint";
NSString * const KGOThemePropertyContentTitle = @"ContentTitle";
NSString * const KGOThemePropertyContentSubtitle = @"ContentSubtitle";
NSString * const KGOThemePropertyPageTitle = @"PageTitle";
NSString * const KGOThemePropertyPageSubtitle = @"PageSubtitle";
NSString * const KGOThemePropertyCaption = @"Caption";
NSString * const KGOThemePropertyByline = @"Byline";
NSString * const KGOThemePropertyNavListTitle = @"NavListTitle";
NSString * const KGOThemePropertyNavListSubtitle = @"NavListSubtitle";
NSString * const KGOThemePropertyNavListLabel = @"NavListLabel";
NSString * const KGOThemePropertyNavListValue = @"NavListValue";
NSString * const KGOThemePropertySectionHeader = @"SectionHeader";
NSString * const KGOThemePropertySectionHeaderGrouped = @"SectionHeaderGrouped";
NSString * const KGOThemePropertyTab = @"Tab";
NSString * const KGOThemePropertyTabSelected = @"TabSelected";

@interface KGOTheme (Private)

- (UIColor *)matchBackgroundColorWithLabel:(NSString *)label;

@end



@implementation KGOTheme

static KGOTheme *s_sharedTheme = nil;

+ (KGOTheme *)sharedTheme {
    if (s_sharedTheme == nil) {
        s_sharedTheme = [[KGOTheme alloc] init];
    }
    return s_sharedTheme;
}

- (UIFont *)defaultFont
{
    return [UIFont fontWithName:[self defaultFontName] size:[self defaultFontSize]];
}

- (UIFont *)defaultBoldFont
{
    NSString *fontName = [self defaultFontName];
    CGFloat size = [self defaultFontSize];
    UIFont *font = [UIFont fontWithName:[NSString stringWithFormat:@"%@-Bold", fontName]
                                   size:size];
    if (!font) {
        font = [UIFont fontWithName:fontName size:size];
    }
    return font;
}

- (NSString *)defaultFontName
{
    NSString *fontName = [fontDict stringForKey:@"DefaultFont" nilIfEmpty:YES];
    if (!fontName) {
        fontName = [[UIFont systemFontOfSize:[UIFont systemFontSize]] fontName];
    }
    return fontName;
}

- (CGFloat)defaultFontSize
{
    CGFloat fontSize = [fontDict floatForKey:@"DefaultFontSize"];
    if (!fontSize) {
        fontSize = [UIFont systemFontSize];
    }
    return fontSize;
}

- (UIFont *)fontForThemedProperty:(NSString *)themeProperty
{
    UIFont *font = nil;
    
    NSString *fontName = nil;
    CGFloat fontSize = [self defaultFontSize];
    
    NSDictionary *fontInfo = [fontDict objectForKey:themeProperty];
    
    if (fontInfo) {
        fontName = [fontInfo stringForKey:@"font" nilIfEmpty:YES];
        fontSize += [fontInfo floatForKey:@"size"];
        if ([fontInfo boolForKey:@"bold"]) {
            // short circuit if bold font is defined
            font = [UIFont fontWithName:[NSString stringWithFormat:@"%@-Bold", fontName]
                                   size:fontSize];
        } else {
            font = [UIFont fontWithName:fontName size:fontSize];
        }
        
    } else {
        font = [UIFont fontWithName:[self defaultFontName] size:fontSize];
    }
    
    if (!font) {
        font = [UIFont systemFontOfSize:fontSize];
    }
    
    return font;
}

- (UIColor *)textColorForThemedProperty:(NSString *)themeProperty
{
    UIColor *color = nil;
    NSDictionary *fontInfo = [fontDict objectForKey:themeProperty];
    if (fontInfo) {
        NSString *hexString = [fontInfo objectForKey:@"color"];
        if (hexString) {
            color = [UIColor colorWithHexString:hexString];
        }
    }
    
    if (!color) {
        color = [UIColor blackColor];
    }
    
    return color;
}

#pragma mark Homescreen

- (NSDictionary *)homescreenConfig
{
    return [themeDict dictionaryForKey:@"HomeScreen"];
}

#pragma mark Colors

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

- (UIColor *)backgroundColorForPlainSectionHeader {
    UIColor *color = [self matchBackgroundColorWithLabel:@"PlainSectionHeaderBackground"];
    if (!color)
        color = [UIColor blackColor];
    return color;
}

- (UIColor *)backgroundColorForSecondaryCell {
    UIColor *color = [self matchBackgroundColorWithLabel:@"SecondaryCellBackground"];
    if (!color)
        color = [UIColor whiteColor];
    return color;
}

#pragma mark UITableViewCell

// provide None, Blank, and Chevron by default.
// other styles can be defined in theme plist
- (UIImageView *)accessoryViewForType:(NSString *)accessoryType {
    
    static NSDictionary *CellAccessoryImages = nil;
    static NSDictionary *CellAccessoryImagesHighlighted = nil;
    
    if (CellAccessoryImages == nil) {
        CellAccessoryImages = [[NSDictionary alloc] initWithObjectsAndKeys:
                               @"common/action-blank", KGOAccessoryTypeBlank,
                               @"common/action-checkmark", KGOAccessoryTypeCheckmark,
                               @"common/action-arrow", KGOAccessoryTypeChevron,
                               @"common/action-phone", KGOAccessoryTypePhone,
                               @"common/action-people", KGOAccessoryTypePeople,
                               @"common/action-map", KGOAccessoryTypeMap,
                               @"common/action-email", KGOAccessoryTypeEmail,
                               @"common/action-external", KGOAccessoryTypeExternal,
                               nil];
    }
    if (CellAccessoryImagesHighlighted == nil) {
        CellAccessoryImagesHighlighted = [[NSDictionary alloc] initWithObjectsAndKeys:
                                          @"common/action-checkmark-highlighted", KGOAccessoryTypeCheckmark,
                                          @"common/action-arrow-highlighted", KGOAccessoryTypeChevron,
                                          @"common/action-phone-highlighted", KGOAccessoryTypePhone,
                                          @"common/action-people-highlighted", KGOAccessoryTypePeople,
                                          @"common/action-map-highlighted", KGOAccessoryTypeMap,
                                          @"common/action-email-highlighted", KGOAccessoryTypeEmail,
                                          @"common/action-external-highlighted", KGOAccessoryTypeExternal,
                                          nil];
    }
    
    if (accessoryType && ![accessoryType isEqualToString:KGOAccessoryTypeNone]) {
        UIImage *image = [UIImage imageWithPathName:[CellAccessoryImages objectForKey:accessoryType]];
        UIImage *highlightedImage = [UIImage imageWithPathName:[CellAccessoryImages objectForKey:accessoryType]];
        if (image) {
            if (highlightedImage) {
                return [[[UIImageView alloc] initWithImage:image highlightedImage:highlightedImage] autorelease];
            }
            return [[[UIImageView alloc] initWithImage:image] autorelease];
        }
    }
    return nil;
}

#pragma mark - Private

- (void)loadFontPreferences
{
    NSMutableDictionary *mutableFontDict = [[[themeDict objectForKey:@"Fonts"] mutableCopy] autorelease];
    NSDictionary *userSettings = [[NSUserDefaults standardUserDefaults] objectForKey:KGOUserPreferencesKey];
    if (userSettings) {
        // TODO: reduce the hard-coded ness of our settings overrides
        CGFloat fontSize = [[mutableFontDict objectForKey:@"DefaultFontSize"] floatValue];
        if (!fontSize) {
            fontSize = [UIFont systemFontSize];
        }

        NSString *fontSizePref = [userSettings objectForKey:@"DefaultFontSize"];
        if ([fontSizePref isEqualToString:@"Tiny"]) {
            fontSize -= 3;
        } else if ([fontSizePref isEqualToString:@"Small"]) {
            fontSize -= 1.5;
        } else if ([fontSizePref isEqualToString:@"Large"]) {
            fontSize += 1.5;
        } else if ([fontSizePref isEqualToString:@"Huge"]) {
            fontSize += 3;
        }
        [mutableFontDict setObject:[NSNumber numberWithFloat:fontSize] forKey:@"DefaultFontSize"];
        
        NSString *fontPref = [userSettings objectForKey:@"DefaultFont"];
        if (fontPref) {
            UIFont *font = [UIFont fontWithName:fontPref size:fontSize];
            if (font) {
                [mutableFontDict setObject:fontPref forKey:@"DefaultFont"];
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

- (id)init
{
    self = [super init];
    if (self) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            NSString *file = [[NSBundle mainBundle] pathForResource:@"ThemeConfig-iPad" ofType:@"plist"];
            themeDict = [[NSDictionary alloc] initWithContentsOfFile:file];
        }
        if (!themeDict) {
            NSString *file = [[NSBundle mainBundle] pathForResource:@"ThemeConfig" ofType:@"plist"];
            themeDict = [[NSDictionary alloc] initWithContentsOfFile:file];
        }
        [self loadFontPreferences];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userDefaultsDidChange:)
                                                     name:KGOUserPreferencesDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
	fontDict = nil;
    [themeDict release];
    [super dealloc];
}

@end
