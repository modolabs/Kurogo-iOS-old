#import "TwitterModule.h"
#import "KGOSocialMediaController.h"
#import "KGOHomeScreenWidget.h"
#import "KGOTheme.h"

@implementation TwitterModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    
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



- (NSArray *)widgetViews {
    NSString *title = @"This is a fake Twitter widget";
    
    UIFont *font = [[KGOTheme sharedTheme] fontForBodyText];
    CGSize size = [title sizeWithFont:font constrainedToSize:CGSizeMake(140, 200) lineBreakMode:UILineBreakModeWordWrap];
    
    NSMutableArray *widgets = [NSMutableArray array];
    
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(5, 5, size.width, size.height)] autorelease];
    label.numberOfLines = 0;
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.font = font;
    label.text = title;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor redColor];
    
    KGOHomeScreenWidget *widget = [[[KGOHomeScreenWidget alloc] initWithFrame:CGRectMake(0, 0, size.width + 10, size.height + 10)] autorelease];
    [widget addSubview:label];
    widget.gravity = KGOLayoutGravityBottomLeft;
    
    [widgets addObject:widget];

    return widgets;
}

#pragma mark Social media controller

- (NSSet *)socialMediaTypes {
    return [NSSet setWithObject:KGOSocialMediaTypeTwitter];
}

@end
