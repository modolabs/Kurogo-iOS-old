#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOSpringboardViewController.h"
#import "HarvardNavigationController.h"
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
    
    [self loadModulesFromArray:moduleData];
}

- (void)loadHomeModule {
    NSArray *moduleData = [[self appConfig] objectForKey:@"Modules"];
    NSDictionary *homeData = nil;
    for (NSDictionary *aDict in moduleData) {
        if ([[aDict objectForKey:@"class"] isEqualToString:@"HomeModule"]) {
            homeData = aDict;
            break;
        }
    }
    if (!homeData) {
        homeData = [NSDictionary dictionaryWithObjectsAndKeys:
                    @"HomeModule", @"class",
                    @"home", @"tag", nil];
    }
    KGOModule *homeModule = [KGOModule moduleWithDictionary:homeData];

    NSArray *modules = nil;
    if (_modules) {
        modules = [_modules arrayByAddingObject:homeModule];
    } else {
        modules = [NSArray arrayWithObject:homeModule];
    }
    [_modules release];
    _modules = [modules copy];

    NSMutableDictionary *modulesByTag = nil;
    if (_modulesByTag) {
        modulesByTag = [_modulesByTag mutableCopy];
    } else {
        modulesByTag = [NSDictionary dictionaryWithObject:homeModule forKey:homeModule.tag];
    }
    [_modulesByTag release];
    _modulesByTag = [modulesByTag copy];
}

- (void)loadModulesFromArray:(NSArray *)moduleArray {
    NSMutableDictionary *modulesByTag = [[_modulesByTag mutableCopy] autorelease];
    if (!modulesByTag) {
        modulesByTag = [NSMutableDictionary dictionaryWithCapacity:[moduleArray count]];
    }
    NSMutableArray *modules = [[_modules mutableCopy] autorelease];
    if (!modules) {
        modules = [NSMutableArray array];
    }
    
    for (NSDictionary *moduleDict in moduleArray) {
        if ([[moduleDict objectForKey:@"class"] isEqualToString:@"HomeModule"])
            continue;
        
        KGOModule *aModule = [KGOModule moduleWithDictionary:moduleDict];
        if (aModule) {
            [modules addObject:aModule];
            [modulesByTag setObject:aModule forKey:aModule.tag];
            [aModule applicationDidFinishLaunching];
        }
    }

    [_modules release];
    _modules = [modules copy];

    [_modulesByTag release];
    _modulesByTag = [modulesByTag copy];

    [[NSNotificationCenter defaultCenter] postNotificationName:ModuleListDidChangeNotification object:self];
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
                _appNavController = [[HarvardNavigationController alloc] initWithRootViewController:homeVC];
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
    return [_modulesByTag objectForKey:aTag];
}

- (BOOL)showPage:(NSString *)pageName forModuleTag:(NSString *)moduleTag params:(NSDictionary *)params {
    BOOL didShow = NO;

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

- (UIViewController *)visibleViewController {
    if (_appNavController) {
        return _appNavController.visibleViewController;
    } else if (_appHomeScreen && [_appHomeScreen isKindOfClass:[KGOSidebarFrameViewController class]]) {
        return [(KGOSidebarFrameViewController *)_appHomeScreen visibleViewController];
    }
    return nil;
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

- (UIViewController *)homescreen {
    if (_appNavController) {
        return [[_appNavController viewControllers] objectAtIndex:0];
    } else if (_appHomeScreen) {
        return _appHomeScreen;
    }
    return nil;
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
