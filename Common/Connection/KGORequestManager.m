#import "KGORequestManager.h"
#import "Foundation+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "CoreDataManager.h"
#import "Reachability.h"
#import "KGOModule.h"

NSString * const HelloRequestDidCompleteNotification = @"HelloDidComplete";
NSString * const HelloRequestDidFailNotification = @"HelloDidFail";
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
		[self showAlertForError:error request:request];
	}
	return request;
}

- (void)showAlertForError:(NSError *)error request:(KGORequest *)request
{
    [self showAlertForError:error request:request delegate:self];
}

- (void)showAlertForError:(NSError *)error request:(KGORequest *)request delegate:(id<UIAlertViewDelegate>)delegate
{
    DLog(@"%@", [error userInfo]);
    
	NSString *title = nil;
	NSString *message = nil;
    BOOL canRetry = NO;
	
	switch ([error code]) {
		case KGORequestErrorBadRequest: case KGORequestErrorUnreachable:
			title = NSLocalizedString(@"Connection Failed", nil);
			message = NSLocalizedString(@"Could not connect to server. Please try again later.", nil);
            canRetry = YES;
			break;
		case KGORequestErrorDeviceOffline:
			title = NSLocalizedString(@"Connection Failed", nil);
			message = NSLocalizedString(@"Please check your Internet connection and try again.", nil);
            canRetry = YES;
			break;
		case KGORequestErrorTimeout:
			title = NSLocalizedString(@"Connection Timed Out", nil);
			message = NSLocalizedString(@"Server is taking too long to respond. Please try again later.", nil);
            canRetry = YES;
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
            canRetry = YES;
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
        if (delegate == self) {
            [_retryRequest release];
            _retryRequest = [request retain];
        }
        
        NSString *retryOption = nil;
        if (canRetry) {
            retryOption = NSLocalizedString(@"Retry", nil);
        }
        
		UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:title
                                                             message:message
                                                            delegate:delegate
                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                   otherButtonTitles:retryOption, nil] autorelease];
		[alertView show];
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != [alertView cancelButtonIndex]) {
        [_retryRequest connect];
        [_retryRequest release];
        _retryRequest = nil;
    }
}

#pragma mark Push notifications

NSString * const KGOPushDeviceIDKey = @"KGOPushDeviceID";
NSString * const KGOPushDevicePassKeyKey = @"KGOPushDevicePassKey";
NSString * const KGODeviceTokenKey = @"KGODeviceToken";

- (void)registerNewDeviceToken
{
    
    if (!self.devicePushToken) {
        DLog(@"cannot register nil device token");
        return;
    }
    
    if (_deviceRegistrationRequest) {
        DLog(@"device registration request already in progress");
        return;
    }
    
    NSDictionary *params = nil;

    // this will be of the form "<21d34 2323a 12324>"
    NSString *hex = [self.devicePushToken description];
	// eliminate the "<" and ">" and " "
	hex = [hex stringByReplacingOccurrencesOfString:@"<" withString:@""];
	hex = [hex stringByReplacingOccurrencesOfString:@">" withString:@""];
	hex = [hex stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (self.devicePushID && self.devicePushPassKey) {
        // we should only get here if Apple changes our device token,
        // which we've never actually seen happen before
        params = [NSDictionary dictionaryWithObjectsAndKeys:
                  self.devicePushID, @"device_id",
                  self.devicePushPassKey, @"pass_key",
                  @"ios", @"platform",
                  hex, @"device_token",
                  nil];
        
        // TODO: do something safer than hard coding "push" as the module tag
        _deviceRegistrationRequest = [self requestWithDelegate:self
                                                        module:@"push"
                                                          path:@"updatetoken"
                                                        params:params];
        
    } else {
        params = [NSDictionary dictionaryWithObjectsAndKeys:
                  @"ios", @"platform",
                  hex, @"device_token",
                  nil];
        
        // TODO: do something safer than hard coding "push" as the module tag
        _deviceRegistrationRequest = [self requestWithDelegate:self
                                                        module:@"push"
                                                          path:@"register"
                                                        params:params];
    }
    
    [_deviceRegistrationRequest connect];
}

- (NSString *)devicePushID
{
    // if the user doesn't register,
    // this will keep doing extra work and returning nil anyway
    if (!_devicePushID) {
        _devicePushID = [[[NSUserDefaults standardUserDefaults] stringForKey:KGOPushDeviceIDKey] retain];
    }
    return _devicePushID;
}

- (NSString *)devicePushPassKey
{
    if (!_devicePushPassKey) {
        _devicePushPassKey = [[[NSUserDefaults standardUserDefaults] stringForKey:KGOPushDevicePassKeyKey] retain];
    }
    return _devicePushPassKey;
}

- (NSData *)devicePushToken
{
    return [[NSUserDefaults standardUserDefaults] dataForKey:KGODeviceTokenKey];
}

- (void)setDevicePushToken:(NSData *)devicePushToken
{
    [[NSUserDefaults standardUserDefaults] setObject:devicePushToken forKey:KGODeviceTokenKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
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
        
        self.devicePushToken = [[NSUserDefaults standardUserDefaults] objectForKey:KGODeviceTokenKey];
	}
	return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

	self.host = nil;
    
    [_helloRequest cancel];
    [_sessionRequest cancel];
    [_logoutRequest cancel];
    [_deviceRegistrationRequest cancel];
    
    [_extendedHost release];
    [_reachability release];
	[_uriScheme release];
	[_accessToken release];
    
    [_devicePushID release];
    [_devicePushPassKey release];
    self.devicePushToken = nil;
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
        DLog(@"attempting to show modal login screen");
        UIViewController *homescreen = [KGO_SHARED_APP_DELEGATE() homescreen];
        if (homescreen.modalViewController) {
            DLog(@"already showing modal login screen");
            return;
        }
        KGOModule *loginModule = [KGO_SHARED_APP_DELEGATE() moduleForTag:self.loginPath];
        UIViewController *loginController = [loginModule modulePage:LocalPathPageNameHome params:nil];
        loginController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        loginController.modalPresentationStyle = UIModalPresentationFullScreen;
        [homescreen presentModalViewController:loginController animated:YES];
    }
}

- (void)logoutKurogoServer
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:@"1" forKey:@"hard"];
    NSDictionary *userInfo = [_sessionInfo dictionaryForKey:@"user"];
    if (userInfo) {
        NSString *authority = [userInfo stringForKey:@"authority" nilIfEmpty:YES];
        if (authority) {
            [params setObject:authority forKey:@"authority"];
        }
    }

    _logoutRequest = [self requestWithDelegate:self module:self.loginPath path:@"logout" params:params];
    [_logoutRequest connect];
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
        for (NSHTTPCookie *aCookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
            if ([aCookie.domain rangeOfString:[self host]].location != NSNotFound) {
                DLog(@"%@", aCookie);
            }
        }
        
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
    } else if (request == _logoutRequest) {
        _logoutRequest = nil;
    } else if (request == _deviceRegistrationRequest) {
        _deviceRegistrationRequest = nil;
    } else if (request == _logoutRequest) {
        _logoutRequest = nil;
    }
}

- (void)request:(KGORequest *)request didFailWithError:(NSError *)error {
    NSLog(@"%@", [error description]);
    
    if (request == _deviceRegistrationRequest) {
        NSDictionary *userInfo = [error userInfo];
        // TODO: coordinate with kurogo server on error codes.
        // Unauthorized appears to be 4 right now, but 401 or 403 might
        // make more sense.
        NSString *title = [userInfo stringForKey:@"title" nilIfEmpty:YES];
        if ([title isEqualToString:@"Unauthorized"] && ![self isUserLoggedIn]) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:KGODidLoginNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(registerNewDeviceToken)
                                                         name:KGODidLoginNotification
                                                       object:nil];
        }
    }
    else if(request == _helloRequest) {
        [[NSNotificationCenter defaultCenter] postNotificationName:HelloRequestDidFailNotification object:self];
    }
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result {
    if (request == _helloRequest) {
        NSArray *modules = [result arrayForKey:@"modules"];
        DLog(@"received modules from hello: %@", modules);
        [KGO_SHARED_APP_DELEGATE() loadModulesFromArray:modules local:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:HelloRequestDidCompleteNotification object:self];

    } else if (request == _sessionRequest) {
        [_sessionInfo release];
        _sessionInfo = [result retain];
        DLog(@"received session info: %@", _sessionInfo);

        if ([self isUserLoggedIn]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:KGODidLoginNotification object:self];
        }
        
    } else if (request == _deviceRegistrationRequest) {
        DLog(@"registered new device for push notifications: %@", result);
        NSString *deviceID = [result stringForKey:@"device_id" nilIfEmpty:YES];
        NSString *passKey = [result objectForKey:@"pass_key"];
        if ([passKey isKindOfClass:[NSNumber class]]) {
            passKey = [passKey description];
        }
        if (deviceID && [passKey isKindOfClass:[NSString class]]) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:deviceID forKey:KGOPushDeviceIDKey];
            [defaults setObject:passKey forKey:KGOPushDevicePassKeyKey];
            [defaults synchronize];
            
            [[NSNotificationCenter defaultCenter] removeObserver:self name:KGODidLoginNotification object:nil];
        }
        
    } else if (request == _logoutRequest) {
        NSArray *cookies = [[[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies] copy] autorelease];
        for (NSHTTPCookie *aCookie in cookies) {
           if ([[aCookie domain] rangeOfString:[self host]].location != NSNotFound) {
               [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:aCookie];
           }
        }
        
        [_sessionInfo release];
        _sessionInfo = nil;
        
        // TODO: decide how to handle data deletion.
        // e.g. keep track of data on a per-user basis?
        
        if ([[CoreDataManager sharedManager] deleteStore]) {
            DLog(@"deleted store");
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:KGODidLogoutNotification object:self];
    }
}

@end
