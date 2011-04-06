#import "KGOAppDelegate.h"

@interface KGOAppDelegate (ModuleListAdditions)

#pragma mark Setup

- (void)loadModules;
- (void)loadHomeModule;
- (void)loadModulesFromArray:(NSArray *)moduleArray local:(BOOL)isLocal;
- (void)loadNavigationContainer;
- (NSArray *)coreDataModelsNames;

#pragma mark Navigation

- (KGOModule *)moduleForTag:(NSString *)aTag;
- (BOOL)showPage:(NSString *)pageName forModuleTag:(NSString *)moduleTag params:(NSDictionary *)params;
- (UIViewController *)visibleViewController;

@property (nonatomic, readonly) KGONavigationStyle navigationStyle;
@property (nonatomic, readonly) UIViewController *homescreen;

#pragma mark Social Media

- (void)loadSocialMediaController;

@end
