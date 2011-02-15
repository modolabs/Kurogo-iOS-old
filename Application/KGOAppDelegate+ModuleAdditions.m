#import "KGOAppDelegate+ModuleAdditions.h"
#import "SpringboardViewController.h"
#import "ModoNavigationController.h"
#import "KGOTheme.h"
#import "KGOModule.h"
#import "HomeModule.h"
#import "KGOSocialMediaController.h"
#import "AnalyticsWrapper.h"

@implementation KGOAppDelegate (ModuleListAdditions)

#pragma mark Setup

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
    HomeModule *homeModule = (HomeModule *)[self moduleForTag:HomeTag];
    UIViewController *homeVC = [homeModule modulePage:LocalPathPageNameHome params:nil];
    theNavController = [[ModoNavigationController alloc] initWithRootViewController:homeVC];
    theNavController.view.backgroundColor = [[KGOTheme sharedTheme] backgroundColorForApplication];
    [self.window addSubview:theNavController.view];
}

- (NSArray *)coreDataModelsNames {
    if (!_modules) {
        [self loadModules];
    }
    NSMutableArray *modelNames = [NSMutableArray array];
    for (KGOModule *aModule in _modules) {
        NSArray *modelNamesForModule = [aModule objectModelNames];
        if (modelNamesForModule) {
            [modelNames addObjectsFromArray:modelNamesForModule];
        }
    }
    return modelNames;
}

#pragma mark Navigation

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
            // TODO: generalize this check for ipad
            if (_visibleModule != module) {
                [_visibleModule willBecomeHidden];
                [module willBecomeVisible];
                _visibleModule = module;
            }
            
			// if the visible view controller is modal, push new view controllers on the modal nav controller.
			// there should be no reason to push a view controller behind what's visible.
			if (!appModalHolder.view.hidden && appModalHolder.modalViewController.navigationController) {
				[appModalHolder.modalViewController.navigationController pushViewController:vc animated:YES];
			} else {
				[theNavController pushViewController:vc animated:YES];
			}
            
            // tracking
            NSString *pagePath = [NSString stringWithFormat:@"/%@/%@", moduleTag, pageName];
            [[AnalyticsWrapper sharedWrapper] trackPageview:pagePath];
            
            didShow = YES;
        }
    }
    return didShow;
}

- (KGONavigationStyle)navigationStyle {
    return KGONavigationStyleIconGrid;
}

#pragma mark social media

- (void)loadSocialMediaController {
    if (!_modules) {
        [self loadModules];
    }
    NSMutableSet *mediaTypes = [NSMutableSet set];
    for (KGOModule *aModule in _modules) {
        NSSet *moreTypes = [aModule socialMediaTypes];
        if (moreTypes) {
            [mediaTypes unionSet:moreTypes];
            
            // TODO: make sure inputs are acceptable
            for (NSString *mediaType in moreTypes) {
                NSDictionary *settings = [aModule userInfoForSocialMediaType:mediaType];
                for (NSString *setting in [settings allKeys]) {
                    NSArray *options = [settings objectForKey:setting];
                    [[KGOSocialMediaController sharedController] addOptions:options forSetting:setting forMediaType:mediaType];
                }
            }
        }
    }
}

@end
