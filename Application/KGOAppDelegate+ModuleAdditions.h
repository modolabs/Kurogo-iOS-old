#import "KGOAppDelegate.h"

@interface KGOAppDelegate (ModuleListAdditions)

#pragma mark Setup

- (void)loadModules;
- (void)loadNavigationContainer;
- (NSArray *)coreDataModelsNames;

#pragma mark Navigation

- (KGOModule *)moduleForTag:(NSString *)aTag;
- (BOOL)showPage:(NSString *)pageName forModuleTag:(NSString *)moduleTag params:(NSDictionary *)params;
- (UIViewController *)visibleViewController;

@property (nonatomic, readonly) KGONavigationStyle navigationStyle;

#pragma mark Social Media

- (void)loadSocialMediaController;

@end
