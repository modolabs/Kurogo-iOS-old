#import "LoginModule.h"
#import "KGOHomeScreenWidget.h"
#import "KGOTheme.h"
//#import "LoginViewController.h"

@implementation LoginModule
/*
- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [[[LoginViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
    }
    return vc;
}
*/

- (NSArray *)widgetViews {
    NSString *title = @"This widget is just a label";
    
    UIFont *font = [[KGOTheme sharedTheme] fontForContentTitle];
    CGSize size = [title sizeWithFont:font];
    
    UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 10, size.width, size.height)] autorelease];
    titleLabel.font = font;
    titleLabel.text = title;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor grayColor];

    KGOHomeScreenWidget *widget = [[[KGOHomeScreenWidget alloc] initWithFrame:CGRectMake(0, 0, size.width + 20, size.height + 20)] autorelease];
    [widget addSubview:titleLabel];
    
    return [NSArray arrayWithObject:widget];
}

@end
