#import "AboutModule.h"
#import "AboutTableViewController.h"
#import "Foundation+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGORequestManager.h"

@implementation AboutModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        AboutTableViewController * aboutVc = [[[AboutTableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
        aboutVc.moduleTag = self.tag;
        vc = aboutVc;
    }
    else if ([pageName isEqualToString:LocalPathPageNameDetail]) {

        NSString *command = [params objectForKey:@"command"];
        if (command) {
            __block KGOWebViewController *webVC = [[[KGOWebViewController alloc] init] autorelease];
            webVC.title = [params stringForKey:@"title"];
            [webVC applyTemplate:@"modules/about/credits.html"];
            
            KGORequest *request = [[KGORequestManager sharedManager] requestWithDelegate:nil
                                                                                  module:@"about"
                                                                                    path:command
                                                                                 version:1
                                                                                  params:nil];
            request.expectedResponseType = [NSString class];
            request.handler = ^(id jsonObject) {
                webVC.HTMLString = jsonObject;
                return 1;
            };
            [request connect];
            
            vc = webVC;
        }
    }

    return vc;
}

#pragma mark -

- (void)dealloc {
    [super dealloc];
}


@end
