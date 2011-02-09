#import "KGOAppDelegate+ModuleAdditions.h"
#import "SpringboardViewController.h"
#import "ModoNavigationController.h"
#import "KGOTheme.h"
#import "KGOModule.h"

@implementation KGOAppDelegate (ModuleListAdditions)

- (void)loadModules {
    NSArray *moduleData = [[self appConfig] objectForKey:@"Modules"];
    
    NSMutableArray *modules = [NSMutableArray arrayWithCapacity:[moduleData count]];
    for (NSDictionary *moduleDict in moduleData) {
        KGOModule *aModule = [KGOModule moduleWithDictionary:moduleDict];
        if (aModule) {
            [modules addObject:aModule];
        }
    }
    
    _modules = [[NSArray alloc] initWithArray:modules];
    
}

- (void)loadNavigationContainer {
    self.springboard = [[SpringboardViewController alloc] initWithNibName:nil bundle:nil];
    theNavController = [[ModoNavigationController alloc] initWithRootViewController:self.springboard];
    theNavController.view.backgroundColor = [[KGOTheme sharedTheme] backgroundColorForApplication];
    [self.window addSubview:theNavController.view];
}

- (KGOModule *)moduleForTag:(NSString *)aTag {
    for (KGOModule *aModule in self.modules) {
        if ([aModule.tag isEqualToString:aTag]) {
            return aModule;
        }
    }
    return nil;
}

- (BOOL)showPage:(NSString *)pageName forModuleTag:(NSString *)moduleTag params:(NSDictionary *)params {
    BOOL didShow = NO;
    
    KGOModule *module = [self moduleForTag:moduleTag];
    if (module) {
        UIViewController *vc = [module modulePage:pageName params:params];
        if (vc) {
            [theNavController pushViewController:vc animated:YES];
            didShow = YES;
        }
    }
    return didShow;
}

- (KGONavigationStyle)navigationStyle {
    return KGONavigationStyleIconGrid;
}

@end
