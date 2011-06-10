#import "KGOAppDelegate.h"

#define KGO_SHARED_APP_DELEGATE() (KGOAppDelegate *)[[UIApplication sharedApplication] delegate]

@interface KGOAppDelegate (URLHandlers)

- (NSString *)defaultURLScheme;
- (BOOL)handleInternalURL:(NSURL *)url;
- (BOOL)handleFacebookURL:(NSURL *)url;

@end

@interface KGOAppDelegate (Notifications)

- (void)registerForRemoteNotifications:(NSDictionary *)launchOptions;
- (void)updateNotificationUI;
- (void)saveUnreadNotifications;

@property (nonatomic, readonly) NSMutableArray *unreadNotifications;

@end

@interface KGOAppDelegate (ModuleListAdditions)

// TODO: this doesn't make sense in a category called ModuleListAdditions
- (void)showNetworkActivityIndicator;
- (void)hideNetworkActivityIndicator;

#pragma mark Setup

@property (nonatomic, readonly) NSArray *modules;
@property (nonatomic, readonly) NSDictionary *appConfig;

- (void)loadModules;
- (void)loadHomeModule;
- (void)loadModulesFromArray:(NSArray *)moduleArray local:(BOOL)isLocal;
- (void)loadNavigationContainer;
- (NSArray *)coreDataModelNames;

#pragma mark Navigation

- (KGOModule *)moduleForTag:(NSString *)aTag;
- (BOOL)showPage:(NSString *)pageName forModuleTag:(NSString *)moduleTag params:(NSDictionary *)params;
- (UIViewController *)visibleViewController;

@property (nonatomic, readonly) KGONavigationStyle navigationStyle;
@property (nonatomic, readonly) UIViewController *homescreen;
@property (nonatomic, readonly) KGOModule *visibleModule;

#pragma mark Social Media

- (void)loadSocialMediaController;

@end
