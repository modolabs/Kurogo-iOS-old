#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOSpringboardViewController.h"
#import "HarvardNavigationController.h"
#import "KGOSidebarFrameViewController.h"
#import "KGOSplitViewController.h"
#import "KGOTheme.h"
#import "KGOModule+Factory.h"
#import "HomeModule.h"
#import "LoginModule.h"
#import "KGOSocialMediaController.h"
#import "AnalyticsWrapper.h"
#import "Foundation+KGOAdditions.h"
#import "KGORequestManager.h"

@interface KGOAppDelegate (PrivateModuleListAdditions)

- (void)addModule:(KGOModule *)module;

@end

@implementation KGOAppDelegate (PrivateModuleListAdditions)

- (void)addModule:(KGOModule *)aModule
{
    [_modules addObject:aModule];
    [_modulesByTag setObject:aModule forKey:aModule.tag];
    [aModule applicationDidFinishLaunching];
    if ([aModule isKindOfClass:[LoginModule class]]) {
        [[KGORequestManager sharedManager] setLoginPath:aModule.tag];
    }
    DLog(@"new module: %@", [aModule description]);
}

@end


@implementation KGOAppDelegate (ModuleListAdditions)

#pragma mark Setup

- (void)loadModules {
    NSArray *moduleArray = [[self appConfig] arrayForKey:@"Modules"];
    [self loadModulesFromArray:moduleArray local:YES];
}

// we need to do this separately since currently we have no way of
// functioning without the home screen
// TODO: make it possible to start from any module
- (void)loadHomeModule {
    NSDictionary *homeData = nil;
    NSArray *moduleArray = [[self appConfig] arrayForKey:@"Modules"];
    for (NSDictionary *moduleData in moduleArray) {
        if ([[moduleData objectForKey:@"id"] isEqualToString:@"home"]) {
            homeData = moduleData;
            break;
        }
    }
    
    if (!homeData) {
        homeData = [NSDictionary dictionaryWithObjectsAndKeys:
                    @"HomeModule", @"class",
                    @"home", @"tag",
                    nil];
    }
    KGOModule *homeModule = [KGOModule moduleWithDictionary:homeData];
    homeModule.hasAccess = YES;
    [self addModule:homeModule];
}

- (void)loadModulesFromArray:(NSArray *)moduleArray local:(BOOL)isLocal
{
    for (NSDictionary *moduleDict in moduleArray) {
        NSString *tag = [moduleDict stringForKey:@"tag" nilIfEmpty:YES];
        KGOModule *aModule = [self moduleForTag:tag];
        if (aModule) {
            [aModule updateWithDictionary:moduleDict];
            DLog(@"updating module: %@", [aModule description]);
        } else {
            aModule = [KGOModule moduleWithDictionary:moduleDict];
            if (aModule) {
                [self addModule:aModule];
                if (isLocal) {
                    aModule.hasAccess = YES;
                }
            }
        }
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:ModuleListDidChangeNotification object:self];
}

- (void)loadNavigationContainer {
    if (!_appHomeScreen && !_appNavController) {    
        HomeModule *homeModule = (HomeModule *)[self moduleForTag:HomeTag];
        UIViewController *homeVC = [homeModule modulePage:LocalPathPageNameHome params:nil];
        KGONavigationStyle navStyle = [self navigationStyle];
        switch (navStyle) {
            case KGONavigationStyleTabletSidebar:
            case KGONavigationStyleTabletSplitView:
            {
                _appHomeScreen = [homeVC retain];
                self.window.rootViewController = _appHomeScreen;
                break;
            }
            default:
            {
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
                self.window.rootViewController = _appNavController;
                break;
            }
        }
        // TODO: see if there is a better place to put this
        NSString *pagePath = [NSString stringWithFormat:@"/%@/%@", homeModule.tag, LocalPathPageNameHome];
        [[AnalyticsWrapper sharedWrapper] trackPageview:pagePath];
    }
}

- (NSArray *)coreDataModelNames {
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

- (KGOModule *)visibleModule
{
    return _visibleModule;
}

// this should never be called on the home module.
- (BOOL)showPage:(NSString *)pageName forModuleTag:(NSString *)moduleTag params:(NSDictionary *)params {
    BOOL didShow = NO;

    KGOModule *module = [self moduleForTag:moduleTag];
    
    if (module) {
        if (![module isLaunched]) {
            [module launch];
        }

        UIViewController *vc = [module modulePage:pageName params:params];
        if (vc) {
            // storing mainly for calling viewWillAppear on modal transitions,
            // so assuming it's never deallocated when we try to access it
            _visibleViewController = vc;
            
            BOOL moduleDidChange = (_visibleModule != module);

            if (moduleDidChange) {
                [_visibleModule becomeHidden];
                [module becomeVisible];
                _visibleModule = module;
            }
            
            KGONavigationStyle navStyle = [self navigationStyle];
            switch (navStyle) {
                case KGONavigationStyleTabletSidebar:
                {
                    KGOSidebarFrameViewController *sidebarVC = (KGOSidebarFrameViewController *)_appHomeScreen;
                    [sidebarVC showViewController:vc];
                    break;
                }
                case KGONavigationStyleTabletSplitView:
                {
                    KGOSplitViewController *splitVC = (KGOSplitViewController *)_appHomeScreen;
                    if (splitVC.rightViewController.modalViewController) {
                        UIViewController *modalVC = splitVC.rightViewController.modalViewController;
                        if ([modalVC isKindOfClass:[UINavigationController class]]) {
                            [(UINavigationController *)modalVC pushViewController:vc animated:YES];
                        } else if (modalVC.navigationController) {
                            [modalVC.navigationController pushViewController:vc animated:YES];
                        }
                        
                    } else {
                        if (moduleDidChange) {
                            splitVC.isShowingModuleHome = YES;
                            splitVC.rightViewController = vc;
                        } else {
                            splitVC.isShowingModuleHome = NO;
                            [splitVC.rightViewController.navigationController pushViewController:vc animated:YES];
                        }
                    }
                    break;
                }
                default:
                {
                    // if the visible view controller is modal, push new view controllers on the modal nav controller.
                    UIViewController *homescreen = [self homescreen];
                    UIViewController *topVC = homescreen.navigationController.topViewController;
                    
                    if (topVC.modalViewController && [topVC.modalViewController isKindOfClass:[UINavigationController class]]) {
                        [(UINavigationController *)topVC.modalViewController pushViewController:vc animated:YES];
                        
                    } else {
                        [_appNavController pushViewController:vc animated:YES];
                    }
                    break;
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
    KGONavigationStyle navStyle = [self navigationStyle];
    switch (navStyle) {
        case KGONavigationStyleTabletSidebar:
        {
            return _appHomeScreen;
        }
        case KGONavigationStyleTabletSplitView:
        {
            KGOSplitViewController *splitVC = (KGOSplitViewController *)_appHomeScreen;
            return splitVC.rightViewController.navigationController.topViewController;
        }
        default:
        {
            UIViewController *homescreen = [self homescreen];
            return homescreen.navigationController.topViewController;
        }
    }
}

- (KGONavigationStyle)navigationStyle {
    if (_navigationStyle == KGONavigationStyleUnknown) {
        
        NSDictionary *homescreenDict = [[KGOTheme sharedTheme] homescreenConfig];
        NSString *style;
        
        style = [homescreenDict objectForKey:@"NavigationStyle"];
        
        if ([style isEqualToString:@"Grid"]) {
            _navigationStyle = KGONavigationStyleIconGrid;
            
        } else if ([style isEqualToString:@"List"]) {
            _navigationStyle = KGONavigationStyleTableView;
            
        } else if ([style isEqualToString:@"Portlet"]) {
            _navigationStyle = KGONavigationStylePortlet;
            
        } else if ([style isEqualToString:@"Sidebar"] && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            _navigationStyle = KGONavigationStyleTabletSidebar;
            
        } else if ([style isEqualToString:@"SplitView"] && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            _navigationStyle = KGONavigationStyleTabletSplitView;
            
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
