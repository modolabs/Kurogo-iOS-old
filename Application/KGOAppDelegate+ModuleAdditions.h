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

/*
#pragma mark Preferences
- (NSArray *)defaultModuleOrder;
- (void)registerDefaultModuleOrder;
- (void)loadSavedModuleOrder;
- (void)loadActiveModule;
- (void)saveModuleOrder;
- (void)saveModulesState;
*/
@end
