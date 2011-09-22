#import "ContentModule.h"
#import "ContentTableViewController.h"
#import "Foundation+KGOAdditions.h"

@implementation ContentModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        ContentTableViewController *cvc = [[[ContentTableViewController alloc] init] autorelease];
        cvc.moduleTag = self.tag;
        vc = cvc;
        
    } else if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        NSString *key = [params stringForKey:@"key"];
        if (key) {
            ContentTableViewController *cvc = [[[ContentTableViewController alloc] init] autorelease];
            cvc.moduleTag = self.tag;
            cvc.feedKey = key;
            vc = cvc;
        }
    }
    return vc;
}

@end