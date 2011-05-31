#import <Foundation/Foundation.h>

@protocol KGOSearchResultsHolder;
@class KGONotification;

@interface KGOModule : NSObject {
    
    id<KGOSearchResultsHolder> _searchDelegate;

@private
    BOOL _launched;
    BOOL _active;
    BOOL _visible;
}

// generally subclasses will not override this
// except in special cases like ExternalURLModule
- (id)initWithDictionary:(NSDictionary *)moduleDict;


/*
 * you must override methods
 * - (UIViewController *)modulePage:(NSString *)pageID params:(NSDictionary *)params;
 */

#pragma mark API properties

- (BOOL)requiresKurogoServer;

// allow the server to change module title (longName, shortName), api versions
// (apiMinVersion, apiMaxVersion), and access control status (hasAccess).
// tag should not be changed once it is set -- probably want to make readonly.
- (void)updateWithDictionary:(NSDictionary *)moduleDict;

@property (nonatomic, copy) NSString *tag;       // unique

@property (nonatomic) NSInteger apiMinVersion;
@property (nonatomic) NSInteger apiMaxVersion;

@property (nonatomic) BOOL hasAccess;

#pragma mark Appearance on home screen

- (NSArray *)widgetViews; // array of KGOHomeScreenWidget objects, ordered by z-index

@property (nonatomic, copy) NSString *shortName; // what label shows up on home screen
@property (nonatomic, copy) NSString *longName;

@property (nonatomic, retain) UIImage *tabBarImage;
@property (nonatomic, retain) UIImage *listViewImage;
@property (nonatomic, retain) UIImage *iconImage;

@property (nonatomic) BOOL secondary;

@property (nonatomic, retain) NSString *badgeValue;
@property (nonatomic) BOOL enabled; // whether or not the module is available to the user
@property (nonatomic) BOOL hidden; // module is available but not shown on home screen

#pragma mark Navigation

- (NSArray *)registeredPageNames;
- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params;
- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query;

#pragma mark Search

// when state of search results changes, send messages to the delegate
- (void)performSearchWithText:(NSString *)text params:(NSDictionary *)params delegate:(id<KGOSearchResultsHolder>)delegate;

- (NSArray *)cachedResultsForSearchText:(NSString *)text params:(NSDictionary *)params;

@property (nonatomic, readonly) BOOL supportsFederatedSearch;
@property (nonatomic, assign) id<KGOSearchResultsHolder> searchDelegate;

#pragma mark Data

- (NSArray *)objectModelNames;
- (void)clearCachedData;

#pragma mark Module state

/*
 * modules have four states, in order of how much work is being done by/for them:
 * - not launched
 * - launched but not active (no views retained by the app)
 * - active but not visible (views are retained by the app but none are visible)
 * - visible
 */

@property (readonly) BOOL isLaunched; // true if anything controlled by the module (other than self) is retained.
- (void)willLaunch;  // called if necessary components (e.g. data managers) of the module are needed.
- (void)didLaunch;

- (void)willTerminate; // called if module is launched and no aspects of the module are needed (views, data managers, etc.)
- (void)didTerminate;  // module must be safe to release after this is called.

@property (readonly) BOOL isActive;   // true if any views controlled by the module are currently retained.
- (void)willBecomeActive;  // called when view resources need to be set up.
- (void)didBecomeActive;

- (void)willBecomeInactive; // called when view resources are no longer needed, but other aspects (e.g. data managers) may be retained.
- (void)didBecomeInactive;

@property (readonly) BOOL isVisible;  // true if any views controlled by the module is currently visible to the user.
- (void)willBecomeVisible; // called if the module is about to be shown.
- (void)didBecomeVisible;

- (void)willBecomeHidden;  // called on visible module when (an)other module(s) will take up all of the visible screen.
- (void)didBecomeHidden;

// don't override the following

- (void)launch;
- (void)terminate;
- (void)becomeActive;
- (void)becomeInactive;
- (void)becomeVisible;
- (void)becomeHidden;

#pragma mark Application state

// methods forwarded from the application delegate -- should be self explanatory.

- (void)applicationDidEnterBackground;
- (void)applicationWillEnterForeground;
- (void)applicationDidFinishLaunching;
- (void)applicationWillTerminate;

- (void)didReceiveMemoryWarning;

#pragma mark Notifications

- (void)handleRemoteNotification:(KGONotification *)aNotification;
- (void)handleLocalNotification:(KGONotification *)aNotification;

// remote notification tags that this module needs to handle
- (NSSet *)notificationTagNames;

// if the server hello returns a payload for this module, evaluate it
- (void)handleInitialPayload:(NSDictionary *)payload;

#pragma mark Settings

// notification names that get sent by activities within the app that affect
// the settings module.  for example, suppose we are an ipad app with a twitter
// widget from which the user is able to log into twitter.  if this widget is in
// the foreground but the settings module is in the background and still
// visible, we need the settings module to listen for such changes to the login
// status.  this is not a desirable way to update the settings module.
- (NSArray *)applicationStateNotificationNames;

// an array of KGOUserSetting objects
@property (nonatomic, retain) NSArray *userSettings;
- (NSArray *)userSettings;

- (void)resetUserSettings:(BOOL)hard;

#pragma mark Social media

- (NSSet *)socialMediaTypes;
- (NSDictionary *)userInfoForSocialMediaType:(NSString *)mediaType;

@end
