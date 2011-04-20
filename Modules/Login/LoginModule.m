#import "LoginModule.h"
#import "KGOHomeScreenWidget.h"
#import "KGOHomeScreenViewController.h"
#import "KGOTheme.h"
#import "ModalLoginWebViewController.h"
#import "KGORequestManager.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "Foundation+KGOAdditions.h"

@implementation LoginModule

@synthesize username, userDescription;

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        if (![[KGORequestManager sharedManager] isUserLoggedIn]) {        
            ModalLoginWebViewController *webVC = [[[ModalLoginWebViewController alloc] init] autorelease];
            NSURL *loginURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/?nativeApp=true",
                                                    [[KGORequestManager sharedManager] serverURL], self.tag]];
            webVC.loginModule = self;
            webVC.requestURL = loginURL;
            webVC.delegate = self;
            vc = webVC;

        } else {
            
        }
    }
    return vc;
}

- (UIView *)currentUserWidget
{
    NSDictionary *userDict = [[[KGORequestManager sharedManager] sessionInfo] dictionaryForKey:@"user"];
    
    self.username = [userDict stringForKey:@"name" nilIfEmpty:YES];
    
    KGOHomeScreenViewController *homeVC = (KGOHomeScreenViewController *)[KGO_SHARED_APP_DELEGATE() homescreen];
    CGRect frame = [homeVC springboardFrame];
    frame = CGRectMake(10, 10, frame.size.width - 20, 80);
    KGOHomeScreenWidget *widget = [[[KGOHomeScreenWidget alloc] initWithFrame:frame] autorelease];
    
    NSString *title = self.username;
    NSString *subtitle = self.userDescription;
    if (!title) {
        title = self.userDescription;
        subtitle = nil;
    }
    
    UILabel *titleLabel = nil;
    
    if (title) {
        UIFont *font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentTitle];
        CGSize size = [title sizeWithFont:font];
        
        titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 10, size.width, size.height)] autorelease];
        titleLabel.font = font;
        titleLabel.text = title;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textColor = [UIColor whiteColor];
        
        [widget addSubview:titleLabel];
    }
    
    if (subtitle) {
        UIFont *font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyBodyText];
        CGSize size = [self.userDescription sizeWithFont:font];
        UILabel *subtitleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, titleLabel.frame.size.height + 20, size.width, size.height)] autorelease];
        subtitleLabel.font = font;
        subtitleLabel.backgroundColor = [UIColor clearColor];
        subtitleLabel.textColor = [UIColor whiteColor];
        subtitleLabel.text = subtitle;
        
        [widget addSubview:subtitleLabel];
    }
    
    widget.behavesAsIcon = NO;
    
    return widget;
}

- (NSArray *)widgetViews {
    KGONavigationStyle navStyle = [KGO_SHARED_APP_DELEGATE() navigationStyle];
    if (navStyle != KGONavigationStylePortlet) {
        return nil;
    }
    
    NSMutableArray *widgets = [NSMutableArray array];
    UIView *currentUserWidget = [self currentUserWidget];
    if (currentUserWidget) {
        [widgets addObject:currentUserWidget];
    }
    return widgets;
}

- (void)dealloc
{
    self.username = nil;
    self.userDescription = nil;
    [super dealloc];
}

@end
