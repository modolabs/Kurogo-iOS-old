#import <Foundation/Foundation.h>

@protocol KGOSearchResultsHolder;
@class KGONotification;

@interface KGOModule : NSObject {
    
    BOOL _launched;
    BOOL _active;
    BOOL _visible;
    
    id<KGOSearchResultsHolder> _searchDelegate;
}

// generally subclasses will not override this
// except in special cases like ExternalURLModule
- (id)initWithDictionary:(NSDictionary *)moduleDict;


/*
 * you must override methods
 * - (UIViewController *)modulePage:(NSString *)pageID params:(NSDictionary *)params;
 */

#pragma mark API properties

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

#pragma mark Module state

/*
 * modules have four states, in order of how much work is being done by/for them:
 * - not launched
 * - launched but not active (no views retained by the app)
 * - active but not visible (views are retained by the app but none are visible)
 * - visible
 */

@property (readonly) BOOL isLaunched; // true if anything controlled by the module (other than self) is retained.
- (void)launch;     // called if necessary components (e.g. data managers) of the module are needed.
- (void)terminate;  // called if module is launched and no aspects of the module are needed (views, data managers, etc.)
                    // module must be safe to release after this is called.

@property (readonly) BOOL isActive;   // true if any views controlled by the module are currently retained.
- (void)willBecomeActive;  // called when view resources need to be set up.
- (void)willBecomeDormant; // called when view resources are no longer needed, but other aspects (e.g. data managers) may be retained.

@property (readonly) BOOL isVisible;  // true if any views controlled by the module is currently visible to the user.
- (void)willBecomeVisible; // called if the module is about to be shown.
- (void)willBecomeHidden;  // called on visible module when (an)other module(s) will take up all of the visible screen.

#pragma mark Application state

// methods forwarded from the application delegate -- should be self explanatory.

- (void)applicationDidEnterBackground;
- (void)applicationWillEnterForeground;
- (void)applicationDidFinishLaunching;
- (void)applicationWillTerminate;

- (void)didReceiveMemoryWarning;

#pragma mark Notifications

- (void)handleNotification:(KGONotification *)aNotification;

// notification names that get sent by activities within the app that affect
// the settings module.
- (NSArray *)applicationStateNotificationNames;

// names of keys saved in user defaults which get wiped on logout.
- (NSArray *)userDefaults;

#pragma mark Social media

- (NSSet *)socialMediaTypes;
- (NSDictionary *)userInfoForSocialMediaType:(NSString *)mediaType;

@end
