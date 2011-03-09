#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOSpringboardViewController.h"
#import "ModoNavigationController.h"
#import "KGOSidebarFrameViewController.h"
#import "KGOTheme.h"
#import "KGOModule+Factory.h"
#import "HomeModule.h"
#import "KGOSocialMediaController.h"
#import "AnalyticsWrapper.h"

@implementation KGOAppDelegate (ModuleListAdditions)

#pragma mark Setup

- (void)loadModules {
    NSArray *moduleData = [[self appConfig] objectForKey:@"Modules"];
    
    NSMutableArray *modules = [NSMutableArray arrayWithCapacity:[moduleData count]];
    for (NSDictionary *moduleDict in moduleData) {
        KGOModule *aModule = [KGOModule moduleWithDictionary:moduleDict]; // home will return nil
        if (aModule) {
            [modules addObject:aModule];
        }
    }
    
    _modules = [[NSArray alloc] initWithArray:modules];
    
}

- (void)loadNavigationContainer {
    if (!_appHomeScreen && !_appNavController) {    
        HomeModule *homeModule = (HomeModule *)[self moduleForTag:HomeTag];
        UIViewController *homeVC = [homeModule modulePage:LocalPathPageNameHome params:nil];
        if ([self navigationStyle] == KGONavigationStyleTabletSidebar) {
            _appHomeScreen = [homeVC retain];
            [self.window addSubview:homeVC.view];
        } else {
            UIImage *navBarImage = [[KGOTheme sharedTheme] backgroundImageForNavBar];
            if (navBarImage) {
                // for people who insist on using a background image for their nav bar, they 
                // get this unfortunate navigation controller subclass
                _appNavController = [[ModoNavigationController alloc] initWithRootViewController:homeVC];
            } else {
                // normal people get the normal navigation controller
                _appNavController = [[UINavigationController alloc] initWithRootViewController:homeVC];
            }
            _appNavController.view.backgroundColor = [[KGOTheme sharedTheme] backgroundColorForApplication];
            [self.window addSubview:_appNavController.view];
        }
    }
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
NSLog(@"fagwrgnaewinfwngles");

    KGOModule *module = [self moduleForTag:moduleTag];
    if (module) {
        UIViewController *vc = [module modulePage:pageName params:params];
        if (vc) {
            if (_visibleModule != module) {
                [_visibleModule willBecomeHidden];
                [module willBecomeVisible];
                _visibleModule = module;
            }
            
            if ([self navigationStyle] == KGONavigationStyleTabletSidebar) {
                KGOSidebarFrameViewController *sidebarVC = (KGOSidebarFrameViewController *)_appHomeScreen;
                [sidebarVC showViewController:vc];
                
            } else {            
                // if the visible view controller is modal, push new view controllers on the modal nav controller.
                // there should be no reason to push a view controller behind what's visible.
                if (!_appModalHolder.view.hidden && [_appModalHolder.modalViewController isKindOfClass:[UINavigationController class]]) {
                    [(UINavigationController *)_appModalHolder.modalViewController pushViewController:vc animated:YES];
                } else {
                    [_appNavController pushViewController:vc animated:YES];
                }
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
    if (_navigationStyle == KGONavigationStyleUnknown) {
        
        NSString * file = [[NSBundle mainBundle] pathForResource:@"ThemeConfig" ofType:@"plist"];
        NSDictionary *themeDict = [[NSDictionary alloc] initWithContentsOfFile:file];
        NSDictionary *homescreenDict = [[themeDict objectForKey:@"HomeScreen"] retain];
        NSString *style;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            style = [homescreenDict objectForKey:@"NavigationStyle"];
        } else {
            style = [homescreenDict objectForKey:@"TabletNavigationStyle"];
        }
        
        if ([style isEqualToString:@"Grid"]) {
            _navigationStyle = KGONavigationStyleIconGrid;
            
        } else if ([style isEqualToString:@"List"]) {
            _navigationStyle = KGONavigationStyleTableView;
            
        } else if ([style isEqualToString:@"Portlet"]) {
            _navigationStyle = KGONavigationStylePortlet;
            
        } else if ([style isEqualToString:@"Sidebar"] && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            _navigationStyle = KGONavigationStyleTabletSidebar;
            
        } else {
            _navigationStyle = KGONavigationStyleIconGrid;
            
        }
    }
    return _navigationStyle;
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
