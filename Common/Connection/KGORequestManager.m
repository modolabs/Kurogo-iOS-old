#import "KGORequestManager.h"
#import "Foundation+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "CoreDataManager.h"
#import "Reachability.h"
#import "KGOModule.h"

NSString * const HelloRequestDidCompleteNotification = @"HelloComplete";
NSString * const KGODidLoginNotification = @"LoginComplete";
NSString * const KGODidLogoutNotification = @"LogoutComplete";

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
    KGOModule *module = [KGO_SHARED_APP_DELEGATE() moduleForTag:moduleTag];
    return module.hasAccess;
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

- (void)requestServerHello
{
    _helloRequest = [self requestWithDelegate:self module:nil path:@"hello" params:nil];
    _helloRequest.expectedResponseType = [NSDictionary class];
    [_helloRequest connect];
}


- (void)loginKurogoServer
{
    if ([self isUserLoggedIn]) {
        DLog(@"user is already logged in");
        [[NSNotificationCenter defaultCenter] postNotificationName:KGODidLoginNotification object:self];
        
    } else {
        DLog(@"showing modal login screen");
        KGOModule *loginModule = [KGO_SHARED_APP_DELEGATE() moduleForTag:self.loginPath];
        UIViewController *loginController = [loginModule modulePage:LocalPathPageNameHome params:nil];
        loginController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        loginController.modalPresentationStyle = UIModalPresentationFullScreen;
        [[KGO_SHARED_APP_DELEGATE() homescreen] presentModalViewController:loginController animated:YES];
    }
}

- (void)logoutKurogoServer
{
    NSArray *cookies = [[[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies] copy] autorelease];
    for (NSHTTPCookie *aCookie in cookies) {
        if ([[aCookie domain] rangeOfString:[self host]].location != NSNotFound) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:aCookie];
        }
    }
    
    [_sessionInfo release];
    _sessionInfo = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:KGODidLogoutNotification object:self];
    
    // TODO: clean up this request, even though we don't really care if it fails
    [self requestWithDelegate:self module:self.loginPath path:@"logout" params:nil];
}

- (BOOL)isUserLoggedIn
{
    NSDictionary *userInfo = [_sessionInfo dictionaryForKey:@"user"];
    if (userInfo) {
        NSString *authority = [userInfo stringForKey:@"authority" nilIfEmpty:YES];
        if (authority) {
            return YES;
        }
    }
    return NO;
}

- (NSDictionary *)sessionInfo
{
    return _sessionInfo;
}

- (void)requestSessionInfo
{
    if (!_sessionRequest) {
        DLog(@"requesting session info");
        _sessionRequest = [self requestWithDelegate:self module:@"login" path:@"session" params:nil];
        _sessionRequest.expectedResponseType = [NSDictionary class];
        [_sessionRequest connect];
    }
}

- (BOOL)requestingSessionInfo
{
    return _sessionRequest != nil;
}

#pragma mark KGORequestDelegate


- (void)requestWillTerminate:(KGORequest *)request {
    if (request == _helloRequest) {
        _helloRequest = nil;
    } else if (request == _sessionRequest) {
        _sessionRequest = nil;
    }
}

- (void)request:(KGORequest *)request didFailWithError:(NSError *)error {
    NSLog(@"%@", [error description]);
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result {
    if (request == _helloRequest) {
        NSArray *modules = [result arrayForKey:@"modules"];
        [KGO_SHARED_APP_DELEGATE() loadModulesFromArray:modules local:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:HelloRequestDidCompleteNotification object:self];

    } else if (request == _sessionRequest) {
        [_sessionInfo release];
        _sessionInfo = [result retain];
        DLog(@"received session info: %@", _sessionInfo);

        if ([self isUserLoggedIn]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:KGODidLoginNotification object:self];
        }
    }
}

@end
