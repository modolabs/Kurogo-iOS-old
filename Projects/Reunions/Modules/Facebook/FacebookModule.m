#import "FacebookModule.h"
#import "FacebookPhotosViewController.h"
#import "KGOSocialMediaController.h"
#import "KGOHomeScreenWidget.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"

@implementation FacebookModule

// code from http://developer.apple.com/library/ios/#qa/qa2010/qa1480.html
+ (NSDate *)dateFromRFC3339DateTimeString:(NSString *)rfc3339DateTimeString {
    static NSDateFormatter *    sRFC3339DateFormatter;
    NSDate *                    date;
    
    // If the date formatters aren't already set up, do that now and cache them 
    // for subsequence reuse.
    
    if (sRFC3339DateFormatter == nil) {
        NSLocale *                  enUSPOSIXLocale;
        
        sRFC3339DateFormatter = [[NSDateFormatter alloc] init];
        assert(sRFC3339DateFormatter != nil);
        
        enUSPOSIXLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
        assert(enUSPOSIXLocale != nil);
        
        [sRFC3339DateFormatter setLocale:enUSPOSIXLocale];
        [sRFC3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
        [sRFC3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    
    // Convert the RFC 3339 date time string to an NSDate.
    date = [sRFC3339DateFormatter dateFromString:rfc3339DateTimeString];
    return date;
}

- (NSArray *)objectModelNames {
    return [NSArray arrayWithObject:@"FacebookModel"];
}

#pragma mark -

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
    
    // TODO: get rid of magic numbers
    CGRect frame = imageView.frame;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        //frame.origin.x = 5;
        //frame.origin.y = 5;
        frame = CGRectMake(5, 5, 31, 31);
    } else {
        frame = CGRectMake(22, 5, 31, 31);
    }
    imageView.frame = frame;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        CGFloat x = frame.origin.x + frame.size.width + 5;
        frame = CGRectMake(x, 5, 120 - x - 5, 44);
    } else {
        frame = CGRectMake(5, 40, 65, 40);
    }
    UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
    label.font = font;
    label.text = @"Harvard-Radclife '96";
    label.numberOfLines = 0;
    label.lineBreakMode = UILineBreakModeCharacterWrap;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        frame = CGRectMake(0, 0, 120, 44);
    } else {
        frame = CGRectMake(5, 900, 75, 100);
    }
    KGOHomeScreenWidget *widget = [[[KGOHomeScreenWidget alloc] initWithFrame:frame] autorelease];
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
