#import "ScheduleModule.h"
#import "ScheduleViewController.h"

@implementation ScheduleModule

- (void)dealloc {
    [super dealloc];
}

#pragma mark Search

- (BOOL)supportsFederatedSearch {
    return YES;
}

- (void)performSearchWithText:(NSString *)searchText params:(NSDictionary *)params delegate:(id<KGOSearchDelegate>)delegate {

}

#pragma mark Data

- (NSArray *)objectModelNames {
    return nil;
}

#pragma mark Navigation

- (NSArray *)registeredPageNames {
    return nil;
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [[[ScheduleViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
    }
    return vc;
}

@end

