#import "KGORequestManager.h"
#import "Foundation+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "CoreDataManager.h"
#import "Reachability.h"
#import "KGOHomeScreenViewController.h"
#import "KGOModule.h"

NSString * const UserHashCookieName = @"lh";
NSString * const UserTokenCookieName = @"lt";
NSString * const HelloRequestDidCompleteNotification = @"HelloComplete";

@implementation KGORequestManager

@synthesize host = _host, loginPath;

+ (KGORequestManager *)sharedManager {
	static KGORequestManager *s_sharedManager = nil;
	if (s_sharedManager == nil) {
		s_sharedManager = [[KGORequestManager alloc] init];
	}
	return s_sharedManager;
}

- (BOOL)isReachable
{
    return [_reachability currentReachabilityStatus] != NotReachable;
}

- (BOOL)isModuleAvailable:(NSString *)moduleTag
{
    // TODO: add this to hello API
    return YES;
}

- (BOOL)isModuleAuthorized:(NSString *)moduleTag
{
    // TODO: add this to hello API
    return YES;
}

- (NSURL *)serverURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", _uriScheme, _extendedHost]];
}

- (NSURL *)hostURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", _uriScheme, _host]];
}

- (KGORequest *)requestWithDelegate:(id<KGORequestDelegate>)delegate
                             module:(NSString *)module // TODO: now that we have hello, we should check parameter validity
                               path:(NSString *)path
                             params:(NSDictionary *)params
{
	BOOL authorized = YES; // TODO: determine this value

    // TODO: add version parameters v and vmin.  this will become required.

	KGORequest *request = nil;
	if (authorized) {
		request = [[[KGORequest alloc] init] autorelease];
		request.delegate = delegate;
        NSURL *requestBaseURL;
        if (module) {
            requestBaseURL = [[_baseURL URLByAppendingPathComponent:module] URLByAppendingPathComponent:path];
        } else {
            requestBaseURL = [_baseURL URLByAppendingPathComponent:path];
        }
		NSMutableDictionary *mutableParams = [[params mutableCopy] autorelease];
		if (_accessToken) {
			[mutableParams setObject:_accessToken forKey:@"token"];
		}

		request.url = [NSURL URLWithQueryParameters:mutableParams baseURL:requestBaseURL];
		request.module = module;
		request.path = path;
		request.getParams = mutableParams;
	} else {
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:nil];
		NSError *error = [NSError errorWithDomain:KGORequestErrorDomain code:KGORequestErrorForbidden userInfo:userInfo];
		[self showAlertForError:error];
	}
	return request;
}

- (void)showAlertForError:(NSError *)error {
    DLog(@"%@", [error userInfo]);
    
	NSString *title = nil;
	NSString *message = nil;
	
	switch ([error code]) {
		case KGORequestErrorBadRequest: case KGORequestErrorUnreachable:
			title = NSLocalizedString(@"Connection Failed", nil);
			message = NSLocalizedString(@"Could not connect to server. Please try again later.", nil);
			break;
		case KGORequestErrorDeviceOffline:
			title = NSLocalizedString(@"Connection Failed", nil);
			message = NSLocalizedString(@"Please check your Internet connection and try again.", nil);
			break;
		case KGORequestErrorTimeout:
			title = NSLocalizedString(@"Connection Timed Out", nil);
			message = NSLocalizedString(@"Server is taking too long to respond. Please try again later.", nil);
			break;
		case KGORequestErrorForbidden:
			title = NSLocalizedString(@"Unauthorized Request", nil);
			message = NSLocalizedString(@"Unable to perform this request. Please check your login credentials.", nil);
			break;
		case KGORequestErrorVersionMismatch:
			title = NSLocalizedString(@"Unsupported Request", nil);
			NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
			message = [NSString stringWithFormat:@"%@ %@",
					   NSLocalizedString(@"Request is not supported in this version of", nil),
					   [infoDict objectForKey:@"CFBundleName"]];
			break;
		case KGORequestErrorBadResponse: case KGORequestErrorOther:
			title = NSLocalizedString(@"Connection Failed", nil);
			message = NSLocalizedString(@"Problem connecting to server. Please try again later.", nil);
			break;
		case KGORequestErrorServerMessage:
			title = [[error userInfo] objectForKey:@"title"];
			message = [[error userInfo] objectForKey:@"message"];
			break;
		case KGORequestErrorInterrupted: // don't show alert
		default:
			break;
	}
	
	if (title) {
		UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] autorelease];
		[alertView show];
	}
}

#pragma mark initialization

- (id)init {
    self = [super init];
    if (self) {
        NSDictionary *configDict = [KGO_SHARED_APP_DELEGATE() appConfig];
        NSDictionary *servers = [configDict objectForKey:@"Servers"];
        
#ifdef USE_MOBILE_DEV
        NSDictionary *serverConfig = [servers objectForKey:@"Development"];
#else
    #ifdef USE_MOBILE_TEST
        NSDictionary *serverConfig = [servers objectForKey:@"Testing"];
    #else
        #ifdef USE_MOBILE_STAGE
        NSDictionary *serverConfig = [servers objectForKey:@"Staging"];
        #else
        NSDictionary *serverConfig = [servers objectForKey:@"Production"];
        #endif
    #endif
#endif

        BOOL useHTTPS = [serverConfig boolForKey:@"UseHTTPS"];
        
        _uriScheme = useHTTPS ? @"https" : @"http";
        _host = [[serverConfig objectForKey:@"Host"] retain];
        
        NSString *apiPath = [serverConfig objectForKey:@"APIPath"];
        NSString *pathExtension = [serverConfig stringForKey:@"PathExtension" nilIfEmpty:YES];
        if (pathExtension) {
            _extendedHost = [[NSString alloc] initWithFormat:@"%@/%@", _host, pathExtension];
        } else {
            _extendedHost = [_host copy];
        }
        _baseURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@://%@/%@", _uriScheme, _extendedHost, apiPath]];
        
        
        _reachability = [[Reachability reachabilityWithHostName:_host] retain];
	}
	return self;
}

- (void)dealloc {
	self.host = nil;
    [_extendedHost release];
    [_reachability release];
	[_uriScheme release];
	[_accessToken release];
	[super dealloc];
}

#pragma mark auth

- (void)registerWithKurogoServer
{
    _helloRequest = [self requestWithDelegate:self module:nil path:@"hello" params:nil];
    _helloRequest.expectedResponseType = [NSDictionary class];
    [_helloRequest connect];
}


- (void)loginKurogoServer
{
    KGOModule *loginModule = [KGO_SHARED_APP_DELEGATE() moduleForTag:self.loginPath];
    UIViewController *loginController = [loginModule modulePage:LocalPathPageNameHome params:nil];
    loginController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    loginController.modalPresentationStyle = UIModalPresentationFullScreen;
    [KGO_SHARED_APP_DELEGATE() presentAppModalViewController:loginController animated:YES];
}

- (void)logoutKurogoServer
{
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    for (NSHTTPCookie *aCookie in cookies) {
        NSString *name = [aCookie name];
        if ([name isEqualToString:UserHashCookieName]) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:aCookie];
        } else if ([name isEqualToString:UserTokenCookieName]) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:aCookie];
        }
    }
    
    // TODO: clean up this request, even though we don't really care if it fails
    [self requestWithDelegate:self module:self.loginPath path:@"logout" params:nil];
}

- (BOOL)isUserLoggedIn
{
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    
    BOOL userHashCookieExists = NO;
    BOOL userTokenCookieExists = NO;
    
    for (NSHTTPCookie *aCookie in cookies) {
        DLog(@"cookie: %@", [aCookie description]);
        NSString *name = [aCookie name];
        if ([name isEqualToString:UserHashCookieName]) {
            userHashCookieExists = YES;
        } else if ([name isEqualToString:UserTokenCookieName]) {
            userTokenCookieExists = YES;
        }
        if (userTokenCookieExists && userHashCookieExists) {
            return YES;
        }
    }
    return NO;
}

#pragma mark KGORequestDelegate


- (void)requestWillTerminate:(KGORequest *)request {
    if (request == _helloRequest) {
        _helloRequest = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:HelloRequestDidCompleteNotification object:self];
    }
}

- (void)request:(KGORequest *)request didFailWithError:(NSError *)error {
    NSLog(@"%@", [error description]);
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result {
    if (request == _helloRequest) {
        NSArray *modules = [result arrayForKey:@"modules"];
        [KGO_SHARED_APP_DELEGATE() loadModulesFromArray:modules];
    }
}

@end
