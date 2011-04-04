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
            NSURL *loginURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/?nativeApp=true", [[KGORequestManager sharedManager] serverURL], self.tag]];NSLog(@"%@", loginURL);
            webVC.loginModule = self;
            webVC.requestURL = loginURL;
            vc = webVC;

        } else {
            
        }
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
    self.username = [userDict stringForKey:@"name" nilIfEmpty:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:KGOLoginDidCompleteNotification object:self];
}


- (NSArray *)widgetViews {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return nil;
    }

    KGOHomeScreenViewController *homeVC = (KGOHomeScreenViewController *)[KGO_SHARED_APP_DELEGATE() homescreen];
    CGRect frame = [homeVC springboardFrame];
    frame = CGRectMake(10, 10, frame.size.width - 20, 80);
    KGOHomeScreenWidget *widget = [[[KGOHomeScreenWidget alloc] initWithFrame:frame] autorelease];
    
    NSString *title = self.username;
    if (!title) {
        title = @"Anonymous";
    }
    
    UIFont *font = [[KGOTheme sharedTheme] fontForContentTitle];
    CGSize size = [title sizeWithFont:font];
    
    UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 10, size.width, size.height)] autorelease];
    titleLabel.font = font;
    titleLabel.text = title;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor whiteColor];
    
    [widget addSubview:titleLabel];

    if (self.userDescription) {
        font = [[KGOTheme sharedTheme] fontForBodyText];
        size = [self.userDescription sizeWithFont:font];
        UILabel *subtitleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, titleLabel.frame.size.height + 20, size.width, size.height)] autorelease];
        subtitleLabel.font = font;
        subtitleLabel.backgroundColor = [UIColor clearColor];
        subtitleLabel.textColor = [UIColor whiteColor];
        subtitleLabel.text = self.userDescription;

        [widget addSubview:subtitleLabel];
    }
    
    return [NSArray arrayWithObject:widget];
}

- (void)dealloc
{
    self.username = nil;
    self.userDescription = nil;
    [super dealloc];
}

@end
