#import "TwitterModule.h"
#import "KGOSocialMediaController.h"
#import "KGOHomeScreenWidget.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"

@implementation TwitterModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    return nil;
}

- (void)launch {
    [super launch];
    [[KGOSocialMediaController sharedController] startupTwitter];
}

- (void)terminate {
    [super terminate];
    [[KGOSocialMediaController sharedController] shutdownTwitter];
}

#pragma mark View on home screen

// temporary code for creating chat bubble widget
- (KGOHomeScreenWidget *)chatBubbleWidget {
    
    // TODO: add method to appDelegate to get home screen (or split view) boundaries
    CGRect bounds = [[UIScreen mainScreen] applicationFrame];
    CGFloat x = 125;
    KGOHomeScreenWidget *widget = [[[KGOHomeScreenWidget alloc] initWithFrame:CGRectMake(x, 0, bounds.size.width - x - 5, 1)] autorelease];
    
    widget.overlaps = YES;
    UIImageView *leftCap = [[[UIImageView alloc] initWithImage:[UIImage imageWithPathName:@"common/chatbubble-l2.png"]] autorelease];
    UIImageView *rightCap = [[[UIImageView alloc] initWithImage:[UIImage imageWithPathName:@"common/chatbubble-r.png"]] autorelease];
    UIImage *midImage = [[UIImage imageWithPathName:@"common/chatbubble-mid.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    UIImageView *mid = [[[UIImageView alloc] initWithImage:midImage] autorelease];
    
    [widget addSubview:leftCap];
    
    CGRect frame = rightCap.frame;
    frame.origin.x = widget.frame.size.width - rightCap.frame.size.width;
    rightCap.frame = frame;
    [widget addSubview:rightCap];
    
    frame = mid.frame;
    frame.origin.x = leftCap.frame.size.width;
    frame.size.width = widget.frame.size.width - rightCap.frame.size.width;
    mid.frame = frame;
    [widget addSubview:mid];
    
    NSString *text = @"big group going 2 John Harvard's in the Garage, everyone welcome";
    UIFont *font = [[KGOTheme sharedTheme] fontForBodyText];
    UILabel *label = [UILabel multilineLabelWithText:text font:font width:mid.frame.size.width];
    label.frame = mid.frame;
    [widget addSubview:label];
    
    frame = widget.frame;
    frame.size.height = mid.frame.size.height;
    frame.origin.y = bounds.size.height - frame.size.height;
    widget.frame = frame;
    
    widget.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    NSLog(@"%@", [widget description]);
    
    return widget;
}

- (NSArray *)widgetViews {
    
    UIFont *font = [[KGOTheme sharedTheme] fontForBodyText];
    
    NSMutableArray *widgets = [NSMutableArray array];
    
    UIImageView *imageView = [[[UIImageView alloc] initWithImage:[UIImage imageWithPathName:@"modules/twitter/button-twitter.png"]] autorelease];
    CGRect frame = imageView.frame;
    frame.origin.x = 5;
    frame.origin.y = 5;
    imageView.frame = frame;
    
    CGFloat x = frame.origin.x + frame.size.width + 5;
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(x, 5, 120 - x - 5, 44)] autorelease];
    label.font = font;
    label.text = @"#hr15th";
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    
    KGOHomeScreenWidget *widget = [[[KGOHomeScreenWidget alloc] initWithFrame:CGRectMake(0, 0, 120, 44)] autorelease];
    [widget addSubview:imageView];
    [widget addSubview:label];
    widget.gravity = KGOLayoutGravityBottomLeft;
    widget.behavesAsIcon = YES;
    
    [widgets addObject:widget];
    
    [widgets addObject:[self chatBubbleWidget]];

    return widgets;
}

#pragma mark Social media controller

- (NSSet *)socialMediaTypes {
    return [NSSet setWithObject:KGOSocialMediaTypeTwitter];
}

@end
