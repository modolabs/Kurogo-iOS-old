#import "FacebookModule.h"
#import "FacebookPhotosViewController.h"


@implementation FacebookModule

- (UIViewController *)moduleHomeScreenWithParams:(NSDictionary *)args {
    FacebookPhotosViewController *vc = [[[FacebookPhotosViewController alloc] init] autorelease];
    return vc;
}

@end
