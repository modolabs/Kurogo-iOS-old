#import <Foundation/Foundation.h>

#import "MITUnreadNotifications.h"
#import "ModoNavigationController.h"

#define MAX_FEDERATED_SEARCH_RESULTS 5
extern NSString * const LocalPathFederatedSearch;
extern NSString * const LocalPathFederatedSearchResult;

@class MIT_MobileAppDelegate;

@interface MITModule : NSObject {

    NSString *tag; // Internal module name. Never displayed to user.
    NSString *shortName; // The name to be displayed in the UITabBar's first 4 tabBarItems
    NSString *longName; // The name to be displayed in the rows of the More table of the UITabBar
    
    NSString *iconName; // Filename of module artwork. The foo in "Resources/Modules/foo.png".
    
    NSArray *viewControllers;
    
    BOOL canBecomeDefault; // TRUE if this module can become the default tab at startup
    BOOL pushNotificationSupported;
    BOOL pushNotificationEnabled; // toggled by user in SettingsModule
    
    BOOL supportsFederatedSearch;
    CGFloat searchProgress; // between 0 and 1
    NSArray *searchResults;
    id selectedResult;
    BOOL isSearching;
    //NSString *_searchText;
	
	// properties used for saving and restoring state
	// if module keeps track of its state it is required respond to handleLocalPath:query
	BOOL hasLaunchedBegun; // keeps track of if the module has been opened at lease once, since application launch
	NSString *currentPath; // the path of the URL representing current module state
	NSString *currentQuery; // query of the URL representing current module state
}

#pragma mark Required methods (must override in subclass)

- (id)init; // Basic settings: name, icon, root view controller. Keep this minimal. Anything time-consuming needs to be asynchronous.

#pragma mark Optional methods

- (void)applicationDidFinishLaunching; // Called after all modules are initialized and have added their tabNavController to the tab bar
- (void)applicationWillTerminate; // Called before app quits. Last chance to save state.

- (NSString *)description; // what NSLog(@"%@", aModule); prints

- (void)didAppear;

- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query;
- (void)resetURL; // reset the URL, (i.e. path and query to empty strings)

- (void)resetNavStack;
- (void)performSearchForString:(NSString *)searchText;
- (void)setSearchProgress:(CGFloat)progress;
- (void)setSearchResults:(NSArray *)results;
- (void)abortSearch;
- (NSString *)titleForSearchResult:(id)result;
- (NSString *)subtitleForSearchResult:(id)result;

- (BOOL)handleNotification: (MITNotification *)notification appDelegate: (MIT_MobileAppDelegate *)appDelegate shouldOpen: (BOOL)shouldOpen; // Called when a push notification arrives
- (void)handleUnreadNotificationsSync: (NSArray *)unreadNotifications; // called to let the module know the unreads may have changed

- (void)becomeActiveTab;
- (BOOL)isActiveTab;

#pragma mark tabNavController methods

- (void) popToRootViewController;
- (UIViewController *) rootViewController;
- (void) pushViewController: (UIViewController *)viewController;


@property (nonatomic, copy) NSString *tag;
@property (nonatomic, copy) NSString *shortName;
@property (nonatomic, copy) NSString *longName;
@property (nonatomic, copy) NSString *iconName;
@property (nonatomic, retain) NSArray *viewControllers;

@property (nonatomic, assign) CGFloat searchProgress;
@property (nonatomic, retain) NSArray *searchResults;
@property (nonatomic, assign) id selectedResult; // must be a member of searchResults
@property (nonatomic, assign) BOOL supportsFederatedSearch;
@property (nonatomic, readonly) BOOL isSearching;
//@property (nonatomic, retain) NSString *searchText;

@property (nonatomic, assign) BOOL canBecomeDefault;
@property (nonatomic, assign) BOOL pushNotificationSupported;
@property (nonatomic, assign) BOOL pushNotificationEnabled;

@property (nonatomic, retain) NSString *badgeValue;  // What appears in the red bubble in the module's tab. Set to nil to make it disappear. Will eventually show in the More tab's table as well.
@property (nonatomic, readonly) UIImage *icon;       // The icon used for the More tab's table (color)

@property (nonatomic) BOOL hasLaunchedBegun;
@property (nonatomic, retain) NSString *currentPath;
@property (nonatomic, retain) NSString *currentQuery;

@end
