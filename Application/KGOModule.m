#import "UIKit+KGOAdditions.h"
#import "KGOModule.h"
#import "Foundation+KGOAdditions.h"

@implementation KGOModule

@synthesize tag = _tag, shortName = _shortName, longName = _longName;
@synthesize enabled, hidden, badgeValue, tabBarImage, iconImage, listViewImage, secondary, apiMaxVersion, apiMinVersion, hasAccess;
@synthesize searchDelegate;

- (id)initWithDictionary:(NSDictionary *)moduleDict {
    NSLog(@"%@", moduleDict);
    
    
    self = [super init];
    if (self) {
        
        self.hidden = [moduleDict boolForKey:@"hidden"];
        self.secondary = [[moduleDict objectForKey:@"secondary"] boolValue];
        self.tag = [moduleDict objectForKey:@"tag"];

        [self updateWithDictionary:moduleDict];
         
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
        
        
        self.enabled = YES; // TODO: decide what this means or don't use it
    }
    return self;
}

// properties that are allowed to be changed from the server
- (void)updateWithDictionary:(NSDictionary *)moduleDict
{
    // server syntax
    NSString *title = [moduleDict stringForKey:@"title" nilIfEmpty:YES];
    if (title) {
        self.shortName = title;
        self.longName = title;
    } else {        
        self.shortName = [moduleDict objectForKey:@"shortName"];
        self.longName = [moduleDict objectForKey:@"longName"];
    }
    
    self.hasAccess = [moduleDict boolForKey:@"access"];

    // this implies we can't have a version zero of the api
    self.apiMinVersion = [moduleDict integerForKey:@"vmax"];
    self.apiMaxVersion = [moduleDict integerForKey:@"vmin"];
    
    if (!self.apiMaxVersion) self.apiMaxVersion = 1;
    if (!self.apiMinVersion) self.apiMinVersion = 1;
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

- (void)performSearchWithText:(NSString *)text params:(NSDictionary *)params delegate:(id<KGOSearchResultsHolder>)delegate {
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
