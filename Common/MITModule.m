#import "MITModule.h"
#import "MITModuleList.h"
#import "Foundation+MITAdditions.h"
#import "ModoNavigationController.h"

@implementation MITModule

@synthesize tag, shortName, longName, iconName, /*tabNavController, isMovableTab,*/ canBecomeDefault, pushNotificationSupported, pushNotificationEnabled;
@synthesize hasLaunchedBegun, currentPath, currentQuery;
@synthesize viewControllers;
@synthesize supportsFederatedSearch, searchProgress, searchResults, isSearching;
@dynamic badgeValue, icon, tabBarIcon;

#pragma mark -
#pragma mark Required

- (id) init
{
    self = [super init];
    if (self != nil) {

        // Lazily load and prepare modules. that means:
        // Things that can wait until a module is made visible should go into a viewcontroller's -viewDidLoad or -viewWillAppear/-viewDidAppear.
        // Things that must happen at launch time go in -init -> basic properties like name and root view controller. Any loading and processing should be spawned off as an asynchronous action, in order to keep the app responsive.
        // Things that must happen at launch time but require a populated tabbar should go into -applicationDidFinishLaunching.
        
        
        self.tag = @"foo";
        self.shortName = @"foo";
        self.longName = @"Override -init!";
        self.iconName = nil;
        //self.isMovableTab = TRUE;
        self.canBecomeDefault = TRUE;

        // federated search properties
        self.supportsFederatedSearch = NO;
		
		// state related properties
		self.hasLaunchedBegun = NO;
		self.currentPath = nil;
		self.currentQuery = nil;
		
        self.pushNotificationSupported = NO;
        // self.pushNotificationEnabled is set in applicationDidFinishLaunching, because that's when the tag is set
    }
    return self;
}

#pragma mark -
#pragma mark Optional

- (NSString *)description {
    // put whatever you think will be helpful for debugging in here
    return [NSString stringWithFormat:@"%@, an instance of %@", self.tag, NSStringFromClass([self class])];
}

- (void)applicationDidFinishLaunching {
    // Override in subclass to perform tasks after app is setup and all modules have been instantiated.
    // Make sure to call [super applicationDidFinishLaunching]!
    // Avoid using this if possible. Use -init instead, and remember to do time consuming things in a non-blocking way.
    
    // load from disk on app start
    NSDictionary *pushDisabledSettings = [[NSUserDefaults standardUserDefaults] objectForKey:PushNotificationSettingsKey];
    self.pushNotificationEnabled = ([pushDisabledSettings objectForKey:self.tag] == nil) ? YES : NO; // enabled by default

    //self.tabNavController.navigationItem.title = self.longName;
    UIViewController *aVC = [self rootViewController];
    if (aVC) {
        aVC.navigationItem.title = self.longName;
    }
}

- (void)applicationWillTerminate {
    // Save state if needed.
    // Don't do anything time-consuming in here.
    // Keep in mind -[MIT_MobileAppDelegate applicationWillTerminate] already writes NSUserDefaults to disk.
}

- (void)didAppear {
    // Called whenever a module is made visible: tab tapped or entry tapped in More list.
    // If your module needs to do something whenever it appears and it doesn't make sense to do so in a view controller, override this.
}

#pragma mark Saving state and handling external calls

- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query {
    NSLog(@"%@ not handling localPath: %@ query: %@", NSStringFromClass([self class]), localPath, query);
    return NO;
}

- (void)resetURL {
	self.currentPath = @"";
	self.currentQuery = @"";
}

- (void)resetNavStack {
}

- (BOOL)handleNotification:(MITNotification *)notification appDelegate: (MIT_MobileAppDelegate *)appDelegate shouldOpen: (BOOL)shouldOpen {
	//NSLog(@"%@ can not handle notification %@", NSStringFromClass([self class]), notification);
	return NO;
}

- (void)handleUnreadNotificationsSync: (NSArray *)unreadNotifications {
}

- (void)performSearchForString:(NSString *)searchText {
    self.isSearching = YES;
}

- (void)setSearchProgress:(CGFloat)progress {
    searchProgress = progress;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SearchResultsProgressNotification" object:self userInfo:nil];
}

- (void)setSearchResults:(NSArray *)results {
    if (searchResults != results) {
        [searchResults release];
        searchResults = [results retain];
    }
    searchProgress = 1.0;
    self.isSearching = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SearchResultsCompleteNotification" object:self userInfo:nil];
}

- (NSString *)titleForSearchResult:(id)result {
    return @"placeholder";
}

- (NSString *)subtitleForSearchResult:(id)result {
    return nil;
}

#pragma mark -
#pragma mark Use, but don't override

// TODO: get this property reflected in springboard
- (NSString *)badgeValue {
    return nil;
    //return self.tabNavController.tabBarItem.badgeValue;
}

- (void)setBadgeValue:(NSString *)newBadgeValue {
    //self.tabNavController.tabBarItem.badgeValue = newBadgeValue;
}

- (UIImage *)icon {
    UIImage *result = nil;
    if (self.iconName) {
        result = [UIImage imageNamed:[NSString stringWithFormat:@"home/home-%@.png", self.iconName]];
    }
    return result;
}

- (UIImage *)tabBarIcon {
    UIImage *result = nil;
    if (self.iconName) {
        NSString *iconPath = [NSString stringWithFormat:@"%@%@%@%@", [[NSBundle mainBundle] resourcePath], @"/icons/tab-", self.iconName, @".png"];
        result = [UIImage imageWithContentsOfFile:iconPath];
    }
    return result;
}

- (void)becomeActiveTab {
	if(![self isActiveTab]) {
		MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
		[appDelegate showModuleForTag:self.tag];
	}
}

- (BOOL)isActiveTab {
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	return [self.tag isEqualToString:[appDelegate activeModuleTag]];
}

// all notifications are enabled by default
// so we just store which modules are disabled
- (void)setPushNotificationEnabled:(BOOL)enabled; {
	NSMutableDictionary *pushDisabledSettings = [[[NSUserDefaults standardUserDefaults] objectForKey:PushNotificationSettingsKey] mutableCopy];
	if (!pushDisabledSettings) {
        pushDisabledSettings = [[NSMutableDictionary alloc] init];
    }
    pushNotificationEnabled = enabled;
    
	if(enabled) {
		[pushDisabledSettings removeObjectForKey:self.tag];
	} else {
		[pushDisabledSettings setObject:@"disabled" forKey:self.tag];
	}
    
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
	[d setObject:pushDisabledSettings forKey:PushNotificationSettingsKey];
    [d synchronize];
    [pushDisabledSettings release];
}

#pragma mark tabNavController methods

// these methods make sure to pop and push from the current UINavigationController
// which may not be the same as self.tabNavController
- (void) popToRootViewController {
	[[self rootViewController].navigationController popToViewController:[self rootViewController] animated:NO];
}

- (UIViewController *) rootViewController {
    if ([self.viewControllers count]) {
        return [self.viewControllers objectAtIndex:0];
    }
	return nil;
}
		 
- (void) pushViewController: (UIViewController *)viewController {
	[[self rootViewController].navigationController pushViewController:viewController animated:NO];
}

@end
