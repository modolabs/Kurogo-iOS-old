#import "AboutModule.h"
#import "AboutTableViewController.h"
#import "Foundation+KGOAdditions.h"
#import "AboutMITVC.h"
#import "KGOAppDelegate+ModuleAdditions.h"

@implementation AboutModule
@synthesize aboutRequest;
@synthesize webViewTitle;

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        AboutTableViewController * aboutVc = [[[AboutTableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
        aboutVc.moduleTag = self.tag;
        vc = aboutVc;
        
    }

    else if ([pageName isEqualToString:LocalPathPageNameDetail]) {

        NSString * command = [params objectForKey:@"command"];
        self.webViewTitle = [params objectForKey:@"title"];

        
        self.aboutRequest = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                       module:@"about"
                                                                         path:command
                                                                       params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
        
        self.aboutRequest.expectedResponseType = [NSString class];
        if (self.aboutRequest) {
            [self.aboutRequest connect];
        }

    }
    
    else if ([pageName isEqualToString:LocalPathPageNameWebViewDetail]) {
       
        KGOWebViewController * webViewController = [[[KGOWebViewController alloc] init] autorelease];

        
        [webViewController setHTMLString: [params objectForKey:@"htmlString"]];
        webViewController.title = self.webViewTitle;
        vc = webViewController;
    }


    return vc;
}


#pragma mark KGORequestDelegate

- (void)requestWillTerminate:(KGORequest *)request {
    self.aboutRequest = nil;
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result {
    self.aboutRequest = nil;
    
    NSLog(@"%@", [result description]);
    
    if ([result isKindOfClass:[NSString class]])
        [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameWebViewDetail
                           forModuleTag:self.tag 
                                 params:[NSDictionary dictionaryWithObjectsAndKeys:result, @"htmlString", nil]];    

}

#pragma mark -

- (void)dealloc {
    [super dealloc];
    self.aboutRequest = nil;
    self.webViewTitle = nil;
}


@end
