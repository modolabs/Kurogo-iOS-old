#import "UIKit+KGOAdditions.h"
#import "KGOModule.h"
#import "HomeModule.h"
#import "NewsModule.h"
#import "PeopleModule.h"
#import	"MapModule.h"
#import "FullWebModule.h"
#import "SettingsModule.h"
#import "AboutModule.h"
#import "CalendarModule.h"
#import "FacebookModule.h"
#import "LoginModule.h"

@implementation KGOModule

@synthesize tag = _tag, shortName = _shortName, longName = _longName;
@synthesize enabled, badgeValue, tabBarImage, iconImage, listViewImage, secondary;
@synthesize searchDelegate;

- (id)initWithDictionary:(NSDictionary *)moduleDict {
    self = [super init];
    if (self) {
        
        self.shortName = [moduleDict objectForKey:@"shortName"];
        self.longName = [moduleDict objectForKey:@"longName"];
        self.secondary = [[moduleDict objectForKey:@"secondary"] boolValue];
        self.tag = [moduleDict objectForKey:@"tag"];

        NSString *imageName = [moduleDict objectForKey:@"tabBarImage"];
        if (!imageName) {
            imageName = [NSString stringWithFormat:@"modules/home/tab-%@", self.tag];
        }
        self.tabBarImage = [UIImage imageWithPathName:imageName];
        
        imageName = [moduleDict objectForKey:@"iconImage"];
        if (!imageName) {
            imageName = [NSString stringWithFormat:@"modules/home/%@", self.tag];
        }
        self.iconImage = [UIImage imageWithPathName:imageName];
        
        imageName = [moduleDict objectForKey:@"listViewImage"];
        if (!imageName) {
            imageName = [NSString stringWithFormat:@"modules/home/%@-tiny", self.tag];
        }
        self.listViewImage = [UIImage imageWithPathName:imageName];
        
        self.enabled = YES;
    }
    return self;
}

+ (KGOModule *)moduleWithDictionary:(NSDictionary *)args {
    KGOModule *module = nil;
    NSString *className = [args objectForKey:@"class"];
    
    if ([className isEqualToString:@"AboutModule"])
        module = [[[AboutModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"CalendarModule"])
        module = [[[CalendarModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"FullWebModule"])
        module = [[[FullWebModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"MapModule"])
        module = [[[MapModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"NewsModule"])
        module = [[[NewsModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"PeopleModule"])
        module = [[[PeopleModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"SettingsModule"])
        module = [[[SettingsModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"FacebookModule"])
        module = [[[FacebookModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"LoginModule"])
        module = [[[LoginModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"HomeModule"])
        module = [[[HomeModule alloc] initWithDictionary:args] autorelease];

    //else if ([className isEqualToString:@"CoursesModule"])
    
    //else if ([className isEqualToString:@"SchoolsModule"])
    
    //else if ([className isEqualToString:@"DiningModule"])
    
    //else if ([className isEqualToString:@"LibrariesModule"])
    
    //else if ([className isEqualToString:@"TransitModule"])
    
    //else if ([className isEqualToString:@"EmergencyModule"])
    
    return module;
}

- (NSArray *)widgetViews {
    return nil;
}

#pragma mark Navigation

- (NSArray *)registeredPageNames {
    return nil;
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    return nil;
}

- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query {
    return NO;
}

#pragma mark Search

- (void)performSearchWithText:(NSString *)text params:(NSDictionary *)params delegate:(id<KGOSearchDelegate>)delegate {
}

- (NSArray *)cachedResultsForSearchText:(NSString *)text params:(NSDictionary *)params {
    return nil;
}

- (BOOL)supportsFederatedSearch {
    return NO;
}

#pragma mark Data

- (NSArray *)objectModelNames {
    return nil;
}

#pragma mark Module state

- (BOOL)isLaunched {
    return _launched;
}

- (void)launch {
    @synchronized(self) {
        _launched = YES;
    }
}

- (void)terminate {
    if ([self isActive]) {
        [self willBecomeDormant];
    }
    
    @synchronized(self) {
        _launched = NO;
    }
}

- (BOOL)isActive {
    return _active;
}

- (void)willBecomeActive {
    if (![self isLaunched]) {
        [self launch];
    }
    
    @synchronized(self) {
        _active = YES;
    }
}

- (void)willBecomeDormant {
    if ([self isVisible]) {
        [self willBecomeHidden];
    }
    
    @synchronized(self) {
        _active = NO;
    }
}

- (BOOL)isVisible {
    return _visible;
}

- (void)willBecomeVisible {
    if (![self isActive]) {
        [self willBecomeActive];
    }
    
    @synchronized(self) {
        _visible = YES;
    }
}

- (void)willBecomeHidden {
    @synchronized(self) {
        _visible = NO;
    }
}


#pragma mark Application state

// methods forwarded from the application delegate -- should be self explanatory.

- (void)applicationDidEnterBackground {
}

- (void)applicationWillEnterForeground {
}

- (void)applicationDidFinishLaunching {
}

- (void)applicationWillTerminate {
}

- (void)didReceiveMemoryWarning {
}

#pragma mark Notifications

- (void)handleNotification:(KGONotification *)aNotification {
}

#pragma mark Social media

- (NSSet *)socialMediaTypes {
    // register the tags of social media types used
    return nil;
}

- (NSDictionary *)userInfoForSocialMediaType:(NSString *)mediaType {
    // specify if your app uses extra setup arguments
    // for Facebook, enter a list of permissions requested
    return nil;
}

@end
