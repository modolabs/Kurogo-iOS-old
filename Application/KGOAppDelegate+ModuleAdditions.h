#import "KGOAppDelegate.h"

typedef enum {
    KGONavigationStyleUndefined = -1,
    KGONavigationStyleIconGrid,
    KGONavigationStylePortlet,
    KGONavigationStyleTabletSidebar
} KGONavigationStyle;

@interface KGOAppDelegate (ModuleListAdditions)

#pragma mark Setup

- (void)loadModules;
- (void)loadNavigationContainer;
- (NSArray *)coreDataModelsNames;

#pragma mark Navigation

- (KGOModule *)moduleForTag:(NSString *)aTag;
- (BOOL)showPage:(NSString *)pageName forModuleTag:(NSString *)moduleTag params:(NSDictionary *)params;

@property (nonatomic, readonly) KGONavigationStyle navigationStyle;

@end
