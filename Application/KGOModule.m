#import "UIKit+KGOAdditions.h"
#import "KGOModule.h"
#import "Foundation+KGOAdditions.h"
#import "KGORequestManager.h"
#import "KGOUserSettingsManager.h"

@implementation KGOModule

@synthesize tag = _tag, shortName = _shortName, longName = _longName;
@synthesize enabled, hidden, badgeValue, tabBarImage, iconImage, listViewImage, secondary, apiMaxVersion, apiMinVersion, hasAccess;
@synthesize searchDelegate;
@synthesize userSettings;

- (id)initWithDictionary:(NSDictionary *)moduleDict {
    self = [super init];
    if (self) {
        
        self.hidden = [moduleDict boolForKey:@"hidden"];
        self.secondary = [[moduleDict objectForKey:@"secondary"] boolValue];
        NSString *tag = [moduleDict objectForKey:@"tag"];
        if (tag) {
            self.tag = tag;
        }

        //NSString *imageName = [moduleDict objectForKey:@"tabBarImage"];
        NSString *imageName = nil;
        //if (!imageName) {
            imageName = [NSString stringWithFormat:@"modules/home/tab-%@", self.tag];
        //}
        self.tabBarImage = [UIImage imageWithPathName:imageName];
        
        //imageName = [moduleDict objectForKey:@"iconImage"];
        //if (!imageName) {
            imageName = [NSString stringWithFormat:@"modules/home/%@", self.tag];
        //}
        self.iconImage = [UIImage imageWithPathName:imageName];
        
        //imageName = [moduleDict objectForKey:@"listViewImage"];
        //if (!imageName) {
            imageName = [NSString stringWithFormat:@"modules/home/%@-tiny", self.tag];
        //}
        self.listViewImage = [UIImage imageWithPathName:imageName];
        
        [self updateWithDictionary:moduleDict];
    }
    return self;
}

// properties that are allowed to be changed from the server
- (void)updateWithDictionary:(NSDictionary *)moduleDict
{
    // server syntax
    NSString *title = [moduleDict nonemptyStringForKey:@"title"];
    if (title) {
        self.shortName = title;
        self.longName = title;
    }
    
    self.hasAccess = [moduleDict boolForKey:@"access"];

    // this implies we can't have a version zero of the api
    self.apiMinVersion = [moduleDict integerForKey:@"vmax"];
    self.apiMaxVersion = [moduleDict integerForKey:@"vmin"];
    
    if (!self.apiMaxVersion) self.apiMaxVersion = 1;
    if (!self.apiMinVersion) self.apiMinVersion = 1;
    
    NSDictionary *payload = [moduleDict dictionaryForKey:@"payload"];
    if (payload) {
        [self evaluateInitialiationPayload:payload];
    }
}

- (BOOL)requiresKurogoServer
{
    // only set this to YES if a connection is absolutely required (no cache)
    return NO;
}

#pragma Appearance

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

- (BOOL)isActive {
    return _active;
}

- (BOOL)isVisible {
    return _visible;
}

- (void)willLaunch
{
}

- (void)didLaunch
{
}

- (void)launch
{
    if ([self isLaunched]) {
        return;
    }
    
    [self willLaunch];
    
    @synchronized(self) {
        _launched = YES;
    }
    
    [self didLaunch];
}

- (void)willTerminate
{
}

- (void)didTerminate
{
}

- (void)terminate
{
    if (![self isLaunched]) {
        return;
    }
    
    if ([self isActive]) {
        [self becomeInactive];
    }
    
    [self willTerminate];
    
    @synchronized(self) {
        _launched = NO;
    }
    
    [self didTerminate];
}

- (void)willBecomeActive {
}

- (void)didBecomeActive
{
}

- (void)becomeActive
{
    if ([self isActive]) {
        return;
    }
    
    if (![self isLaunched]) {
        [self launch];
    }

    [self willBecomeActive];

    @synchronized(self) {
        _active = YES;
    }

    [self didBecomeActive];
}

- (void)willBecomeInactive
{
}

- (void)didBecomeInactive
{
}

- (void)becomeInactive
{
    if (![self isActive]) {
        return;
    }
    
    if ([self isVisible]) {
        [self becomeHidden];
    }

    [self willBecomeInactive];
    
    @synchronized(self) {
        _active = NO;
    }
    
    [self didBecomeInactive];
}

- (void)willBecomeVisible {
}

- (void)didBecomeVisible
{
}

- (void)becomeVisible
{
    if ([self isVisible]) {
        return;
    }
    
    if (![self isActive]) {
        [self becomeActive];
    }
    
    [self willBecomeVisible];
    
    @synchronized(self) {
        _visible = YES;
    }
    
    [self didBecomeVisible];
}

- (void)willBecomeHidden {
}

- (void)didBecomeHidden
{
}

- (void)becomeHidden
{
    if (![self isVisible]) {
        return;
    }
    
    [self willBecomeHidden];
    
    @synchronized(self) {
        _visible = NO;
    }
    
    [self didBecomeHidden];
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

- (void)handleRemoteNotification:(KGONotification *)aNotification
{
}

- (void)handleLocalNotification:(KGONotification *)aNotification
{
}

- (NSSet *)notificationTagNames
{
    return nil;
}

- (void)evaluateInitialiationPayload:(NSDictionary *)payload
{
}

#pragma mark Settings

- (NSArray *)applicationStateNotificationNames
{
    return nil;
}

- (NSArray *)userSettings
{
    return nil;
}

- (void)resetUserSettings:(BOOL)hard
{
}

- (void)clearCachedData
{
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

#pragma mark NSObject

- (NSString *)description
{
    NSMutableArray *params = [NSMutableArray arrayWithObject:[NSString stringWithFormat:@"tag = %@", self.tag]];
    if (!self.hasAccess) {
        [params addObject:@"hasAccess = NO"];
    }
    if (self.hidden) {
        [params addObject:@"hidden = YES"];
    }
    
    return [NSString stringWithFormat:@"<%@: %p; %@>", [self class], self, [params componentsJoinedByString:@"; "]];
}

@end
