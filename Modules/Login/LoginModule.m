#import "LoginModule.h"
#import "KGOHomeScreenWidget.h"
#import "KGOHomeScreenViewController.h"
#import "KGOTheme.h"
#import "ModalLoginWebViewController.h"
#import "KGORequestManager.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "Foundation+KGOAdditions.h"

@implementation LoginModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        ModalLoginWebViewController *webVC = [[[ModalLoginWebViewController alloc] init] autorelease];
        NSURL *loginURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [[KGORequestManager sharedManager] serverURL], @"login"]];
        webVC.loginModule = self;
        webVC.requestURL = loginURL;
        [KGO_SHARED_APP_DELEGATE() presentAppModalViewController:webVC animated:YES];
    }
    return vc;
}


- (void)userDidLogin
{
    [KGO_SHARED_APP_DELEGATE() dismissAppModalViewControllerAnimated:YES];
    
    _sessionInfoRequest = [[KGORequestManager sharedManager] requestWithDelegate:self module:@"login" path:@"session" params:nil];
    _sessionInfoRequest.expectedResponseType = [NSDictionary class];
    [_sessionInfoRequest connect];
}

- (void)requestWillTerminate:(KGORequest *)request
{
    _sessionInfoRequest = nil;
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result
{
    NSDictionary *userDict = [result dictionaryForKey:@"user"];
    _userName = [[userDict stringForKey:@"name" nilIfEmpty:YES] retain];
    
    [(KGOHomeScreenViewController *)[KGO_SHARED_APP_DELEGATE() homescreen] refreshWidgets];
}


- (NSArray *)widgetViews {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return nil;
    }

    KGOHomeScreenViewController *homeVC = (KGOHomeScreenViewController *)[KGO_SHARED_APP_DELEGATE() homescreen];
    CGRect frame = [homeVC springboardFrame];
    frame = CGRectMake(10, 10, frame.size.width - 20, 80);
    KGOHomeScreenWidget *widget = [[[KGOHomeScreenWidget alloc] initWithFrame:frame] autorelease];
    
    NSString *title = _userName;
    NSString *class = @"Class of 1996"; // _userClass;
    if (!title) {
        title = class;
    }
    
    UIFont *font = [[KGOTheme sharedTheme] fontForContentTitle];
    CGSize size = [title sizeWithFont:font];
    
    UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 10, size.width, size.height)] autorelease];
    titleLabel.font = font;
    titleLabel.text = title;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor whiteColor];
    
    [widget addSubview:titleLabel];

    if (_userName) {
        font = [[KGOTheme sharedTheme] fontForBodyText];
        size = [class sizeWithFont:font];
        UILabel *classLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, titleLabel.frame.size.height + 20, size.width, size.height)] autorelease];
        classLabel.font = font;
        classLabel.backgroundColor = [UIColor clearColor];
        classLabel.textColor = [UIColor whiteColor];
        classLabel.text = class;

        [widget addSubview:classLabel];
    }
    
    return [NSArray arrayWithObject:widget];
}



@end
