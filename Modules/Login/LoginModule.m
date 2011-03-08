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
    NSString *title = @"Carl Fredricksen";
    
    UIFont *font = [[KGOTheme sharedTheme] fontForContentTitle];
    CGSize size = [title sizeWithFont:font];
    
    UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 10, size.width, size.height)] autorelease];
    titleLabel.font = font;
    titleLabel.text = title;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor whiteColor];
    
    NSString *class = @"Class of 1996";
    font = [[KGOTheme sharedTheme] fontForBodyText];
    size = [class sizeWithFont:font];
    UILabel *classLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, titleLabel.frame.size.height + 20, size.width, size.height)] autorelease];
    classLabel.font = font;
    classLabel.backgroundColor = [UIColor clearColor];
    classLabel.textColor = [UIColor whiteColor];
    classLabel.text = class;
    
    CGRect frame = CGRectMake(0, 0,
                              fmaxf(titleLabel.frame.size.width, classLabel.frame.size.width),
                              classLabel.frame.origin.y + classLabel.frame.size.height);

    KGOHomeScreenWidget *widget = [[[KGOHomeScreenWidget alloc] initWithFrame:frame] autorelease];
    [widget addSubview:titleLabel];
    [widget addSubview:classLabel];
    
    return [NSArray arrayWithObject:widget];
}

@end
