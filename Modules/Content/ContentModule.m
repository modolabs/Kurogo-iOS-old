#import "ContentModule.h"
#import "ContentTableViewController.h"
#import "ContentWebViewController.h"
#import "Foundation+KGOAdditions.h"

@implementation ContentModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [[[ContentTableViewController alloc] initWithStyle:UITableViewStyleGrouped moduleTag:self.tag] autorelease];
        
    } else if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        ContentWebViewController * webViewController = [[[ContentWebViewController alloc] init] autorelease];
        KGORequest *feedRequest = [[KGORequestManager sharedManager] requestWithDelegate:webViewController                          
                                                                                  module:self.tag                            
                                                                                    path:@"getFeed"                           
                                                                                  params:params];
        
        [feedRequest connect];
        
        vc = webViewController;
    }
    return vc;
}

@end