#import "PhotosModule.h"
#import "FacebookPhotosViewController.h"
#import "FacebookPhotoDetailViewController.h"
#import "KGOSocialMediaController.h"
#import "KGOHomeScreenWidget.h"
#import "KGOTheme.h"

@implementation PhotosModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [[[FacebookPhotosViewController alloc] initWithNibName:@"FacebookMediaViewController" bundle:nil] autorelease];
    } else if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        FacebookPhoto *photo = [params objectForKey:@"photo"];
        if (photo) {
            vc = [[[FacebookPhotoDetailViewController alloc] initWithNibName:@"FacebookPhotoDetailViewController" bundle:nil] autorelease];
            [(FacebookPhotoDetailViewController *)vc setPhoto:photo];
            NSArray *photos = [params objectForKey:@"photos"];
            if (photos) {
                [(FacebookPhotoDetailViewController *)vc setPhotos:photos];
            }
        }
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

#pragma mark View on home screen


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
                                                   @"user_photos",
                                                   @"friends_photos",
                                                   @"user_likes",
                                                   @"publish_stream",
                                                   nil]
                                           forKey:@"permissions"];
    }
    return nil;
}

@end
