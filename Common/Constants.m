#import "Constants.h"

NSString * const KUROGO_FRAMEWORK_NAME = @"Kurogo iOS";
NSString * const KUROGO_FRAMEWORK_VERSION = @"1.0";

// local path names for handleLocalPath
NSString * const LocalPathPageNameHome = @"index";
NSString * const LocalPathPageNameDetail = @"detail";
NSString * const LocalPathPageNameSearch = @"search";
NSString * const LocalPathPageNameCategoryList = @"categories";
NSString * const LocalPathPageNameItemList = @"items";
NSString * const LocalPathPageNameMapList = @"map";
NSString * const LocalPathPageNameBookmarks = @"bookmarks";
NSString * const LocalPathPageNameWebViewDetail = @"webView";

#pragma mark Config keys

NSString * const KGOAppConfigKeyModules = @"Modules";
NSString * const KGOAppConfigKeyServers = @"Servers";
NSString * const KGOAppConfigKeySocialMedia = @"SocialMedia";

#pragma mark Global NSUserDefaults keys

NSString * const UnreadNotificationsKey = @"UnreadNotifications";

#pragma mark Module tags -- need to eliminate!

ModuleTag * const HomeTag       = @"home";
ModuleTag * const MapTag        = @"map";

#pragma mark App-wide notification names

NSString * const ModuleListDidChangeNotification = @"ModuleListChanged";

NSString * const KGOUserPreferencesKey = @"KGOUserPrefs";
NSString * const KGOUserPreferencesDidChangeNotification = @"KGOUserPrefsChanged";

NSString * const HelloRequestDidCompleteNotification = @"HelloDidComplete";
NSString * const HelloRequestDidFailNotification = @"HelloDidFail";

NSString * const KGODidLoginNotification = @"LoginComplete";
NSString * const KGODidLogoutNotification = @"LogoutComplete";

NSString * const CoreDataDidDeleteStoreNotification = @"CoreDataDidDelete";

#pragma mark Error domains



