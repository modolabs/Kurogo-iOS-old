#import "AboutModule.h"
#import "AboutTableViewController.h"
#import "Foundation+KGOAdditions.h"
#import "AboutMITVC.h"
#import "AboutCreditsWebViewController.h"

@implementation AboutModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        AboutTableViewController * aboutVc = [[[AboutTableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
        aboutVc.moduleTag = self.tag;
        vc = aboutVc;
        
    }
    else if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        
        AboutMITVC *aboutMITVC = [[AboutMITVC alloc] initWithStyle:UITableViewStyleGrouped];
        aboutMITVC.orgName = [params stringForKey:@"orgName" nilIfEmpty:NO];
        aboutMITVC.orgAboutText = [params stringForKey:@"orgText" nilIfEmpty:NO];

        vc = aboutMITVC;
    }
    else if ([pageName isEqualToString:LocalPathPageNameWebViewDetail]) {
        AboutCreditsWebViewController * creditsWebViewController = [[AboutCreditsWebViewController alloc] init];
        NSString * credits = [params stringForKey:@"creditsHTMLString" nilIfEmpty: NO];
        [creditsWebViewController setHTMLString: credits];
        
        vc = creditsWebViewController;
    }

    return vc;
}

@end
