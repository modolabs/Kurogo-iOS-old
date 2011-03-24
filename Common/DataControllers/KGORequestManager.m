#import "KGORequestManager.h"
#import "Foundation+KGOAdditions.h"
#import "KGOAppDelegate.h"
#import "CoreDataManager.h"
#import "Reachability.h"

@implementation KGORequestManager

@synthesize host = _host;

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

- (NSURL *)serverURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", _uriScheme, _extendedHost]];
}

- (NSURL *)hostURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", _uriScheme, _host]];
}

- (KGORequest *)requestWithDelegate:(id<KGORequestDelegate>)delegate module:(NSString *)module path:(NSString *)path params:(NSDictionary *)params {
	BOOL authorized = YES; // TODO: determine this value
	KGORequest *request = nil;
	if (authorized) {
		request = [[[KGORequest alloc] init] autorelease];
		request.delegate = delegate;
		NSURL *requestBaseURL = [[_baseURL URLByAppendingPathComponent:module] URLByAppendingPathComponent:path];
		NSMutableDictionary *mutableParams = [[params mutableCopy] autorelease];
		if (_accessToken) {
			[mutableParams setObject:_accessToken forKey:@"token"];
		}

		request.url = [NSURL URLWithQueryParameters:params baseURL:requestBaseURL];
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

- (void)registerWithKGOServer {
	
}

- (void)authenticateWithKGOServer {
	
}

- (void)dealloc {
	self.host = nil;
    [_extendedHost release];
    [_reachability release];
	[_uriScheme release];
	[_accessToken release];
	[_apiVersionsByModule release];
	[super dealloc];
}

#pragma mark KGORequestDelegate


- (void)requestWillTerminate:(KGORequest *)request {
}

- (void)request:(KGORequest *)request didFailWithError:(NSError *)error {
}

- (void)request:(KGORequest *)request receivedResultDict:(NSDictionary *)result {
}

@end
