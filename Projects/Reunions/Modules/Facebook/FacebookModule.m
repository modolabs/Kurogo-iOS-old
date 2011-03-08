#import "FacebookModule.h"
#import "FacebookPhotosViewController.h"
#import "KGOSocialMediaController.h"
#import "KGOHomeScreenWidget.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"

@implementation FacebookModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [[[FacebookPhotosViewController alloc] init] autorelease];
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



- (NSArray *)widgetViews {
    
    UIFont *font = [[KGOTheme sharedTheme] fontForBodyText];
    
    NSMutableArray *widgets = [NSMutableArray array];
    
    UIImageView *imageView = [[[UIImageView alloc] initWithImage:[UIImage imageWithPathName:@"modules/facebook/button-facebook.png"]] autorelease];
    CGRect frame = imageView.frame;
    frame.origin.x = 5;
    frame.origin.y = 5;
    imageView.frame = frame;
    
    CGFloat x = frame.origin.x + frame.size.width + 5;
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(x, 5, 120 - x - 5, 44)] autorelease];
    label.font = font;
    label.text = @"Harvard-Radclife '96";
    label.numberOfLines = 0;
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    
    KGOHomeScreenWidget *widget = [[[KGOHomeScreenWidget alloc] initWithFrame:CGRectMake(0, 0, 120, 44)] autorelease];
    [widget addSubview:imageView];
    [widget addSubview:label];
    widget.gravity = KGOLayoutGravityBottomLeft;
    widget.behavesAsIcon = YES;
    
    [widgets addObject:widget];

    return widgets;
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
                                                   nil]
                                           forKey:@"permissions"];
    }
    return nil;
}

@end
