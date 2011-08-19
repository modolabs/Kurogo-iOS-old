#import "KGOTwitterService.h"
//#import "SFHFKeychainUtils.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "Foundation+KGOAdditions.h"
#import "KGOSocialMediaController.h"
#import "TwitterViewController.h"

NSString * const TwitterUsernameKey = @"TwitterUsername";
static NSString * const TwitterServiceName = @"Twitter";


@implementation KGOTwitterService

// these are just standard HTTP response codes,
// but some may be accompanied with an additional message that we may eventually want to distinguish.
// http://apiwiki.twitter.com/w/page/22554652/HTTP-Response-Codes-and-Errors
#define TwitterResponseCodeUnauthorized 401

- (void)loginTwitterWithUsername:(NSString *)username password:(NSString *)password {
	//[KGO_SHARED_APP_DELEGATE() showNetworkActivityIndicator];
    _twitterPassword = [password retain];
	self.twitterUsername = username;
	//[_twitterEngine getXAuthAccessTokenForUsername:username password:password];
}

- (NSString *)twitterUsername {
	if (!_twitterUsername) {
        _twitterUsername = [[NSUserDefaults standardUserDefaults] objectForKey:TwitterUsernameKey];
	}
    return _twitterUsername;
}

- (void)setTwitterUsername:(NSString *)username {
	[_twitterUsername release];
	_twitterUsername = [username retain];
    
    [[NSUserDefaults standardUserDefaults] setObject:_twitterUsername forKey:TwitterUsernameKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)postToTwitter:(NSString *)text {
	//[_twitterEngine sendUpdate:text];
}

- (void)postToTwitter:(NSString *)text target:(id)target success:(SEL)successAction failure:(SEL)failureAction
{
    _lastTarget = target;
    _lastSuccessAction = successAction;
    _lastFailureAction = failureAction;
    //_lastConnectionIdentifier = [[_twitterEngine sendUpdate:text] retain];
}

- (void)disconnectTarget:(id)target
{
    if (target == _lastTarget) {
        _lastTarget = nil;
    }
}

- (void)dealloc
{
    [_oauthKey release];
    [_oauthSecret release];
    [_twitterUsername release];
    [_twitterPassword release];
    //[_twitterEngine release];
    
    [super dealloc];
}

#pragma mark KGOSocialMediaService implementation

- (id)initWithConfig:(NSDictionary *)config
{
    self = [super init];
    if (self) {
        _oauthKey = [[config stringForKey:@"OAuthConsumerKey" nilIfEmpty:YES] retain];
        _oauthSecret = [[config stringForKey:@"OAuthConsumerSecret" nilIfEmpty:YES] retain];
    }
    return self;
}

- (void)startup {
    _twitterStartupCount++;
    /*
	if (!_twitterEngine) {
		_twitterEngine = [[MGTwitterEngine alloc] initWithDelegate:self];
		[_twitterEngine setConsumerKey:_oauthKey secret:_oauthSecret];
        
        NSString *username = [self twitterUsername];
        if (username) {
            NSError *error = nil;
            NSString *password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:TwitterServiceName error:&error];
            if (!password || error) {
                NSLog(@"something went wrong looking up access token, error=%@", error);
            } else {
                //[KGO_SHARED_APP_DELEGATE() showNetworkActivityIndicator];
                [_twitterEngine getXAuthAccessTokenForUsername:username password:password];
                return;
            }
        }
	}
    */
}

- (void)shutdown {
    if (_twitterStartupCount > 0)
        _twitterStartupCount--;
    
    if (_twitterStartupCount <= 0) {
        //if (_twitterEngine) {
        //    [_twitterEngine closeAllConnections];
        //    [_twitterEngine release];
        //    _twitterEngine = nil;
        //}
    }
}

- (BOOL)isSignedIn {
    return NO;
    //return _twitterEngine.accessToken != nil;
}

- (void)signin {
    TwitterViewController *twitterVC = [[[TwitterViewController alloc] init] autorelease];
    twitterVC.delegate = self;
    UINavigationController *navC = [[[UINavigationController alloc] initWithRootViewController:twitterVC] autorelease];
    navC.modalPresentationStyle = UIModalPresentationCurrentContext;
    UIViewController *visibleVC = [KGO_SHARED_APP_DELEGATE() visibleViewController];
    [visibleVC presentModalViewController:navC animated:YES];
}

- (void)signout {

    //_twitterEngine.accessToken = nil;
    
    // cleanup
    
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:TwitterUsernameKey];
    if (username) {
        NSError *error = nil;
        //[SFHFKeychainUtils deleteItemForUsername:username andServiceName:TwitterServiceName error:&error];
        
        if (error) {
            NSLog(@"failed to log out of Twitter: %@", [error description]);
        }
    }
    self.twitterUsername = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TwitterDidLogoutNotification object:nil];
}

- (NSString *)userDisplayName
{
    return self.twitterUsername;
}

- (NSString *)serviceDisplayName
{
    return NSLocalizedString(@"Twitter", nil);
}

#pragma mark TwitterViewControllerDelegate

- (BOOL)controllerShouldContinueToMessageScreen:(TwitterViewController *)controller
{
    return NO;
}

- (void)controllerDidLogin:(TwitterViewController *)controller
{
    [controller.navigationController.parentViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark MGTwitterEngineDelegate

// TODO: figure out when we really need to show the network activity indicator
/*
// gets called in response to -[getXAuthAccessTokenForUsername:password:]
- (void)accessTokenReceived:(OAToken *)aToken forRequest:(NSString *)connectionIdentifier {
	NSError *error = nil;
    //[_twitterEngine setAccessToken:aToken];
    
	//[KGO_SHARED_APP_DELEGATE() hideNetworkActivityIndicator];
    if (_twitterPassword) {
        //[SFHFKeychainUtils storeUsername:_twitterUsername
        //                     andPassword:_twitterPassword
        //                  forServiceName:TwitterServiceName
        //                  updateExisting:YES
        //                           error:&error];
        
        [_twitterPassword release];
        _twitterPassword = nil;
        
        if (!error) {
            [[NSUserDefaults standardUserDefaults] setObject:_twitterUsername forKey:TwitterUsernameKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
        } else {
            NSLog(@"error on saving token=%@", [error description]);
        }
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:TwitterDidLoginNotification object:self];
}
*/
- (void)requestSucceeded:(NSString *)connectionIdentifier {
	//[KGO_SHARED_APP_DELEGATE() hideNetworkActivityIndicator];
    
    if (connectionIdentifier == _lastConnectionIdentifier) {
        [_lastConnectionIdentifier release];
        _lastConnectionIdentifier = nil;
        
        if (_lastSuccessAction) {
            [_lastTarget performSelector:_lastSuccessAction];
        }
    }
}

- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error {
	//[KGO_SHARED_APP_DELEGATE() hideNetworkActivityIndicator];

    id<UIAlertViewDelegate> alertViewDelegate = nil;
    
    if (connectionIdentifier == _lastConnectionIdentifier) {
        [_lastConnectionIdentifier release];
        _lastConnectionIdentifier = nil;
        
        alertViewDelegate = _lastTarget;
    }
    
	NSString *errorTitle;
	NSString *errorMessage;
    
    DLog(@"%@", error);
	
	if (error.code == TwitterResponseCodeUnauthorized) {
		errorTitle = NSLocalizedString(@"Login failed", nil);
		errorMessage = NSLocalizedString(@"Unable to log in to Twitter, please check your credentials and try again.", nil);
		
		[self signout];
		
	} else {
		errorTitle = NSLocalizedString(@"Connection Failed", nil);
		errorMessage = NSLocalizedString(@"Unable to connect to Twitter, please try again later.", nil);
	}
	
	UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:errorTitle 
														 message:errorMessage
														delegate:alertViewDelegate
											   cancelButtonTitle:NSLocalizedString(@"OK", nil) 
											   otherButtonTitles:nil] autorelease];
	[alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (_lastFailureAction) {
        [_lastTarget performSelector:_lastFailureAction];
    }
}

- (void)connectionStarted:(NSString *)connectionIdentifier {
	[KGO_SHARED_APP_DELEGATE() showNetworkActivityIndicator];
}

- (void)connectionFinished:(NSString *)connectionIdentifier {
	[KGO_SHARED_APP_DELEGATE() hideNetworkActivityIndicator];
}

@end
