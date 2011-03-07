#import "VideosModule.h"
#import "FacebookVideosViewController.h"
#import "KGOSocialMediaController.h"
#import "KGOHomeScreenWidget.h"
#import "KGOTheme.h"

@implementation VideosModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [[[FacebookVideosViewController alloc] init] autorelease];
    }
    return vc;
}

- (void)launch {
    [super launch];
    [[KGOSocialMediaController sharedController] startupFacebook];
}

- (void)terminate {
    [super terminate];
    [[KGOSocialMediaController sharedController] shutdownFacebook];
}

#pragma mark Social media controller

- (NSSet *)socialMediaTypes {
    return [NSSet setWithObject:KGOSocialMediaTypeFacebook];
}

- (NSDictionary *)userInfoForSocialMediaType:(NSString *)mediaType {
    if ([mediaType isEqualToString:KGOSocialMediaTypeFacebook]) {
        return [NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:
                                                   @"read_stream",
                                                   @"offline_access",
                                                   @"user_groups",
                                                   @"user_videos",
                                                   @"friends_videos",
                                                   nil]
                                           forKey:@"permissions"];
    }
    return nil;
}

@end
