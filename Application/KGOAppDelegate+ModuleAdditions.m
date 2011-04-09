#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOSpringboardViewController.h"
#import "HarvardNavigationController.h"
#import "KGOSidebarFrameViewController.h"
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

- (void)addModule:(KGOModule *)module
{
    NSArray *modules = nil;
    if (_modules) {
        modules = [_modules arrayByAddingObject:module];
    } else {
        modules = [NSArray arrayWithObject:module];
    }
    [_modules release];
    _modules = [modules copy];
    
    NSMutableDictionary *modulesByTag = nil;
    if (_modulesByTag) {
        modulesByTag = [_modulesByTag mutableCopy];
    } else {
        modulesByTag = [NSDictionary dictionaryWithObject:module forKey:module.tag];
    }
    [_modulesByTag release];
    _modulesByTag = [modulesByTag copy];
}

@end


@implementation KGOAppDelegate (ModuleListAdditions)

#pragma mark Setup

- (void)loadModules {
    NSArray *moduleData = [[self appConfig] objectForKey:@"Modules"];
    [self loadModulesFromArray:moduleData local:YES];
}

// we need to do this separately since currently we have no way of
// functioning without the home screen
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
                    @"home", @"tag",
                    @"hidden", [NSNumber numberWithBool:YES],
                    nil];
    }
    KGOModule *homeModule = [KGOModule moduleWithDictionary:homeData];
    homeModule.hasAccess = YES;

    [self addModule:homeModule];
}

- (void)loadModulesFromArray:(NSArray *)moduleArray local:(BOOL)isLocal {
    NSMutableDictionary *modulesByTag = [[_modulesByTag mutableCopy] autorelease];
    if (!modulesByTag) {
        modulesByTag = [NSMutableDictionary dictionaryWithCapacity:[moduleArray count]];
    }
    NSMutableArray *modules = [[_modules mutableCopy] autorelease];
    if (!modules) {
        modules = [NSMutableArray array];
    }
    
    for (NSDictionary *moduleDict in moduleArray) {
        NSString *tag = [moduleDict stringForKey:@"tag" nilIfEmpty:YES];
        KGOModule *aModule = [self moduleForTag:tag];
        if (aModule) {
            [aModule updateWithDictionary:moduleDict];
            DLog(@"updating module: %@", [aModule description]);
        } else {
            aModule = [KGOModule moduleWithDictionary:moduleDict];
            if (aModule) {
                [modules addObject:aModule];
                [modulesByTag setObject:aModule forKey:aModule.tag];
                [aModule applicationDidFinishLaunching];
                if ([aModule isKindOfClass:[LoginModule class]]) {
                    [[KGORequestManager sharedManager] setLoginPath:aModule.tag];
                }
                DLog(@"new module: %@", [aModule description]);
            }
        }
        
        if (isLocal) {
            aModule.hasAccess = YES;
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

// this should never be called on the home module.
- (BOOL)showPage:(NSString *)pageName forModuleTag:(NSString *)moduleTag params:(NSDictionary *)params {
    BOOL didShow = NO;

    KGOModule *module = [self moduleForTag:moduleTag];
    
    if (module) {
        [module launch];

        UIViewController *vc = [module modulePage:pageName params:params];
        if (vc) {
            // storing mainly for calling viewWillAppear on modal transitions,
            // so assuming it's never deallocated when we try to access it
            _visibleViewController = vc;
            
            if (_visibleModule != module) {
                [_visibleModule willBecomeHidden];
                [module willBecomeVisible];
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
                    UISplitViewController *splitVC = (UISplitViewController *)_appHomeScreen;
                    UIViewController *detailVC = [splitVC.viewControllers objectAtIndex:1];
                    if (detailVC.modalViewController) {
                        if ([detailVC.modalViewController isKindOfClass:[UINavigationController class]]) {
                            [(UINavigationController *)detailVC.modalViewController pushViewController:vc animated:YES];
                        } else if (detailVC.modalViewController.navigationController) {
                            [detailVC.modalViewController.navigationController pushViewController:vc animated:YES];
                        }
                        
                    } else {
                        splitVC.viewControllers = [NSArray arrayWithObjects:
                                                   [splitVC.viewControllers objectAtIndex:0],
                                                   vc,
                                                   nil];
                    }
                    break;
                }
                default:
                {
                    // if the visible view controller is modal, push new view controllers on the modal nav controller.
                    // there should be no reason to push a view controller behind what's visible.
                    // TODO: get rid of appModalHolder and thus the first condition here
                    UIViewController *homescreen = [self homescreen];
                    UIViewController *topVC = homescreen.navigationController.topViewController;
                    
                    if (!_appModalHolder.view.hidden
                        && [_appModalHolder.modalViewController isKindOfClass:[UINavigationController class]]
                    ) {
                        [(UINavigationController *)_appModalHolder.modalViewController pushViewController:vc animated:YES];
                        
                    } else if (topVC.modalViewController && [topVC.modalViewController isKindOfClass:[UINavigationController class]]) {
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
    if (_appNavController) {
        return _appNavController.visibleViewController;
    } else if (_appHomeScreen && [_appHomeScreen isKindOfClass:[KGOSidebarFrameViewController class]]) {
        return [(KGOSidebarFrameViewController *)_appHomeScreen visibleViewController];
    }
    return nil;
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
