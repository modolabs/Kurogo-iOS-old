#import "KGOSocialMediaController.h"
#import "SFHFKeychainUtils.h"
#import "KGOAppDelegate.h"
#import "Foundation+KGOAdditions.h"
#import "JSON.h"

NSString * const KGOSocialMediaTypeFacebook = @"Facebook";
NSString * const KGOSocialMediaTypeTwitter = @"Twitter";
NSString * const KGOSocialMediaTypeEmail = @"Email";
NSString * const KGOSocialMediaTypeBitly = @"bit.ly";
NSString * const KGOSocialMediaTypeFoursquare = @"Foursquare";

// NSUserDefaults
static NSString * const TwitterUsernameKey = @"TwitterUsername";
static NSString * const TwitterServiceName = @"Twitter";

static NSString * const FacebookTokenKey = @"FBToken";
static NSString * const FacebookTokenPermissions = @"FBTokenPermissions";
static NSString * const FacebookTokenExpirationSetting = @"FBTokenExpiration";

NSString * const FacebookUsernameKey = @"FBUsername";

// NSNotifications
NSString * const TwitterDidLoginNotification = @"TwitterLoggedIn";
NSString * const TwitterDidLogoutNotification = @"TwitterLoggedOut";

NSString * const FacebookDidLoginNotification = @"FBDidLogin";
NSString * const FacebookDidLogoutNotification = @"FBDidLogout";



@interface KGOSocialMediaController (Private)

- (void)closeBitlyConnection;

@end


static KGOSocialMediaController *s_controller = nil;

@implementation KGOSocialMediaController

@synthesize bitlyDelegate;

+ (KGOSocialMediaController *)sharedController {
	if (s_controller == nil) {
		s_controller = [[KGOSocialMediaController alloc] init];
	}
	return s_controller;
}

- (void)addOptions:(NSArray *)options forSetting:(NSString *)setting forMediaType:(NSString *)mediaType {
    if (!_apiSettings) {
        _apiSettings = [[NSMutableDictionary alloc] init];
    }
    
    NSMutableDictionary *mediaDictionary = [[_apiSettings objectForKey:mediaType] mutableCopy];
    if (!mediaDictionary) {
        mediaDictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:options, setting, nil];
    } else {
        NSMutableArray *existingValues = [[[mediaDictionary objectForKey:setting] mutableCopy] autorelease];
        if (existingValues) {
            [existingValues addObjectsFromArray:options];
            NSSet *uniqueValues = [NSSet setWithArray:existingValues];
            [mediaDictionary setObject:[uniqueValues allObjects] forKey:setting];
        } else {
            [mediaDictionary setObject:options forKey:setting];
        }
    }
    [_apiSettings setObject:mediaDictionary forKey:mediaType];
    [mediaDictionary release];
}

- (id)init {
    self = [super init];
    if (self) {
        NSDictionary *infoDict = [KGO_SHARED_APP_DELEGATE() appConfig];
		_appConfig = [[infoDict objectForKey:@"SocialMedia"] retain];
	}
	return self;
}

- (void)dealloc {
	[self shutdownTwitter];
	[self shutdownFacebook];
	[self shutdownBitly];
	
	[_apiSettings release];
	[_appConfig release];
	
	[super dealloc];
}

#pragma mark Capabilities

- (NSArray *)allSupportedSharingTypes {
    NSMutableArray *array = [NSMutableArray array];
    if ([self supportsEmailSharing]) {
        [array addObject:KGOSocialMediaTypeEmail];
    }
    if ([self supportsFacebookSharing]) {
        [array addObject:KGOSocialMediaTypeFacebook];
    }
    if ([self supportsTwitterSharing]) {
        [array addObject:KGOSocialMediaTypeTwitter];
    }
	return array;
}

- (BOOL)supportsSharing {
	return [[self allSupportedSharingTypes] count] > 0;
}

- (BOOL)supportsFacebookSharing {
    NSDictionary *facebookConfig = [_appConfig objectForKey:KGOSocialMediaTypeFacebook];
    NSString *appID = [facebookConfig stringForKey:@"AppID" nilIfEmpty:YES];
    return appID != nil;
}

- (BOOL)supportsTwitterSharing {
	NSDictionary *twitterConfig = [_appConfig objectForKey:KGOSocialMediaTypeTwitter];
    NSString *key = [twitterConfig stringForKey:@"OAuthConsumerKey" nilIfEmpty:YES];
    return key != nil;
}

- (BOOL)supportsEmailSharing {
	return [_appConfig objectForKey:KGOSocialMediaTypeEmail] != nil;
}

- (BOOL)supportsBitlyURLShortening {
    NSDictionary *bitlyConfig = [_appConfig objectForKey:KGOSocialMediaTypeBitly];
    NSString *username = [bitlyConfig stringForKey:@"Username" nilIfEmpty:YES];
    return username != nil;
}

- (BOOL)supportsFoursquare {
    NSDictionary *foursquareConfig = [_appConfig objectForKey:KGOSocialMediaTypeFoursquare];
    NSString *clientID = [foursquareConfig stringForKey:@"ClientID" nilIfEmpty:YES];
    return clientID != nil;
}

- (BOOL)supportsService:(NSString *)service
{
    if ([service isEqualToString:KGOSocialMediaTypeFacebook]) {
        return [self supportsFacebookSharing];
        
    } else if ([service isEqualToString:KGOSocialMediaTypeTwitter]) {
        return [self supportsTwitterSharing];
        
    } else if ([service isEqualToString:KGOSocialMediaTypeFoursquare]) {
        return [self supportsFoursquare];
        
    }
    return NO;
}

#pragma mark Generic queries by service name

- (BOOL)isLoggedInService:(NSString *)service
{
    if ([self supportsService:service]) {
        if ([service isEqualToString:KGOSocialMediaTypeFacebook]) {
            return [self isFacebookLoggedIn];
            
        } else if ([service isEqualToString:KGOSocialMediaTypeTwitter]) {
            return [self isTwitterLoggedIn];
            
        } else if ([service isEqualToString:KGOSocialMediaTypeFoursquare]) {
            // this method is defined in an optional category
            // TODO: move method here
            if ([self respondsToSelector:@selector(isFoursquareLoggedIn)]) {
                
            }
        }
    }
    return NO;
}

- (void)loginService:(NSString *)service
{
    if ([self supportsService:service]) {
        if ([service isEqualToString:KGOSocialMediaTypeFacebook]) {
            [self loginFacebook];
            
        } else if ([service isEqualToString:KGOSocialMediaTypeTwitter]) {
            [self loginTwitter];
            
        } else if ([service isEqualToString:KGOSocialMediaTypeFoursquare]) {
            // this method is defined in an optional category
            // TODO: move category methods here if they are essential
            if ([self respondsToSelector:@selector(loginFoursquare)]) {
                [self performSelector:@selector(loginFoursquare)];
            }
        }
    }  
}

- (void)logoutService:(NSString *)service
{
    if ([self supportsService:service]) {
        if ([service isEqualToString:KGOSocialMediaTypeFacebook]) {
            [self logoutFacebook];
            
        } else if ([service isEqualToString:KGOSocialMediaTypeTwitter]) {
            [self logoutTwitter];
            
        } else if ([service isEqualToString:KGOSocialMediaTypeFoursquare]) {
            // this method is defined in an optional category
            // TODO: move category methods here if they are essential
            if ([self respondsToSelector:@selector(logoutFoursquare)]) {
                [self performSelector:@selector(logoutFoursquare)];
            }
        }
    }  
}

+ (NSString *)localizedNameForService:(NSString *)service
{
    if ([service isEqualToString:KGOSocialMediaTypeEmail]) {
        return NSLocalizedString(@"Email", nil);
        
    } else if ([service isEqualToString:KGOSocialMediaTypeFacebook]) {
        return NSLocalizedString(@"Facebook", nil);
        
    } else if ([service isEqualToString:KGOSocialMediaTypeTwitter]) {
        return NSLocalizedString(@"Twitter", nil);
        
    } else if ([service isEqualToString:KGOSocialMediaTypeFoursquare]) {
        return NSLocalizedString(@"Foursquare", nil);
        
    }
    return service;
}

#pragma mark -
#pragma mark bit.ly

- (void)getBitlyURLForLongURL:(NSString *)longURL delegate:(id<BitlyWrapperDelegate>)delegate {
	self.bitlyDelegate = delegate;

	NSString *username = [[_appConfig objectForKey:KGOSocialMediaTypeBitly] objectForKey:@"Username"];
	NSString *key = [[_appConfig objectForKey:KGOSocialMediaTypeBitly] objectForKey:@"APIKey"];

	[KGO_SHARED_APP_DELEGATE() showNetworkActivityIndicator];
	_bitlyConnection = [(ConnectionWrapper *)[ConnectionWrapper alloc] initWithDelegate:self]; // cast because multiple classes implement -initWithDelegate
	NSString *bitlyURLString = [NSString stringWithFormat:@"http://api.bit.ly/v3/shorten"
								"?login=%@"
								"&apiKey=%@"
								"&longURL=%@"
								"&format=json",
								username, key, longURL];
	
	NSURL *url = [NSURL URLWithString:bitlyURLString];
	[_bitlyConnection requestDataFromURL:url];
}

- (void)shutdownBitly {
	if (_bitlyConnection) {
		[_bitlyConnection cancel];
        [self closeBitlyConnection];
	}
}

#pragma mark bit.ly - ConnectionWrapper

- (void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
	SBJsonParser *jsonParser = [[[SBJsonParser alloc] init] autorelease];
    NSString *jsonString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    NSError *error = nil;
    id result = [jsonParser objectWithString:jsonString error:&error];
    if (result && [result isKindOfClass:[NSDictionary class]]) {
        NSDictionary *urlData = [result dictionaryForKey:@"data"];
        if (urlData) {
            NSString *shortURL = [urlData stringForKey:@"url" nilIfEmpty:YES];
			[self.bitlyDelegate didGetBitlyURL:shortURL];
        }
    }
    [self closeBitlyConnection];
}

- (BOOL)connection:(ConnectionWrapper *)connection shouldDisplayAlertForError:(NSError *)error {
    return YES;
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError:(NSError *)error {
	if (wrapper == _bitlyConnection) {
		if ([self.bitlyDelegate respondsToSelector:@selector(failedToGetBitlyURL)]) {
			[self.bitlyDelegate failedToGetBitlyURL];
		}
	}
    [self closeBitlyConnection];
}

- (void)closeBitlyConnection {
	[KGO_SHARED_APP_DELEGATE() hideNetworkActivityIndicator];
    [_bitlyConnection release];
    _bitlyConnection = nil;
}

#pragma mark -
#pragma mark Twitter

// these are just standard HTTP response codes,
// but some may be accompanied with an additional message that we may eventually want to distinguish.
// http://apiwiki.twitter.com/w/page/22554652/HTTP-Response-Codes-and-Errors
#define TwitterResponseCodeUnauthorized 401

- (void)startupTwitter {
    _twitterStartupCount++;
    
	if (!_twitterEngine) {
		_twitterEngine = [[MGTwitterEngine alloc] initWithDelegate:self];
        
		NSString *key = [[_appConfig objectForKey:KGOSocialMediaTypeTwitter] objectForKey:@"OAuthConsumerKey"];
		NSString *secret = [[_appConfig objectForKey:KGOSocialMediaTypeTwitter] objectForKey:@"OAuthConsumerSecret"];
		[_twitterEngine setConsumerKey:key secret:secret];
	}
}

- (void)shutdownTwitter {
    if (_twitterStartupCount > 0)
        _twitterStartupCount--;

    if (_twitterStartupCount <= 0) {
        if (_twitterEngine) {
            [_twitterEngine closeAllConnections];
            [_twitterEngine release];
            _twitterEngine = nil;
        }
    }
}

- (BOOL)isTwitterLoggedIn {
    return _twitterEngine.accessToken != nil;
}

// TODO: make this function more usable
- (BOOL)loginTwitter {
	NSString *username = [self twitterUsername];
	if (!username) {
		return NO;
	}
	
	NSError *error = nil;
	NSString *password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:TwitterServiceName error:&error];
	if (error) {
		NSLog(@"something went wrong looking up access token, error=%@", error);
		return NO;
	}
	
	[_twitterEngine getXAuthAccessTokenForUsername:username password:password];
    return YES;
}

- (void)loginTwitterWithUsername:(NSString *)username password:(NSString *)password {
	[KGO_SHARED_APP_DELEGATE() showNetworkActivityIndicator];
	self.twitterUsername = username;
	[_twitterEngine getXAuthAccessTokenForUsername:username password:password];
}

- (void)logoutTwitter {
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:TwitterUsernameKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:TwitterUsernameKey];
	
	NSError *error = nil;
	[SFHFKeychainUtils deleteItemForUsername:username andServiceName:TwitterServiceName error:&error];
	
	if (error) {
		NSLog(@"failed to log out of Twitter: %@", [error description]);
	}
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TwitterDidLogoutNotification object:nil];
}

- (void)postToTwitter:(NSString *)text {
	[_twitterEngine sendUpdate:text];
}

- (NSString *)twitterUsername {
	if (_twitterUsername) {
		return _twitterUsername;
	}
    return [[NSUserDefaults standardUserDefaults] objectForKey:TwitterUsernameKey];
}

- (void)setTwitterUsername:(NSString *)username {
	[_twitterUsername release];
	_twitterUsername = [username retain];
}

#pragma mark Twitter - MGTwitterEngineDelegate

// gets called in response to -[getXAuthAccessTokenForUsername:password:]
- (void)accessTokenReceived:(OAToken *)aToken forRequest:(NSString *)connectionIdentifier {
	NSError *error = nil;
    [_twitterEngine setAccessToken:aToken];
    
	[KGO_SHARED_APP_DELEGATE() hideNetworkActivityIndicator];
    
	if (!error) {
		[[NSUserDefaults standardUserDefaults] setObject:_twitterUsername forKey:TwitterUsernameKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:TwitterDidLoginNotification object:self];
	} else {
		NSLog(@"error on saving token=%@", [error description]);
	}
}

- (void)requestSucceeded:(NSString *)connectionIdentifier {
	[KGO_SHARED_APP_DELEGATE() hideNetworkActivityIndicator];
}

- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error {
	[KGO_SHARED_APP_DELEGATE() hideNetworkActivityIndicator];
	
	NSString *errorTitle;
	NSString *errorMessage;
	
	if (error.code == TwitterResponseCodeUnauthorized) {
		errorTitle = NSLocalizedString(@"Login failed", nil);
		errorMessage = NSLocalizedString(@"Unable to log in to Twitter, please check your credentials and try again.", nil);
		
		[self logoutTwitter];
		
	} else {
		errorTitle = NSLocalizedString(@"Connection Failed", nil);
		errorMessage = NSLocalizedString(@"Unable to connect to Twitter, please try again later.", nil);
	}
	
	UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:errorTitle 
														 message:errorMessage
														delegate:nil 
											   cancelButtonTitle:NSLocalizedString(@"OK", nil) 
											   otherButtonTitles:nil] autorelease];
	[alertView show];
}


- (void)connectionStarted:(NSString *)connectionIdentifier {
	[KGO_SHARED_APP_DELEGATE() showNetworkActivityIndicator];
}

- (void)connectionFinished:(NSString *)connectionIdentifier {
	[KGO_SHARED_APP_DELEGATE() hideNetworkActivityIndicator];
}


#pragma mark - Facebook

- (BOOL)isFacebookLoggedIn {
    return [_facebook isSessionValid];
}

- (void)parseCallbackURL:(NSURL *)url {
    NSLog(@"handling facebook callback url");
    NSString *fragment = [url fragment];
    NSArray *parts = [fragment componentsSeparatedByString:@"&"];
    for (NSString *aPart in parts) {
        NSArray *param = [aPart componentsSeparatedByString:@"="];
        NSString *key = [param objectAtIndex:0];
        NSString *value = [param objectAtIndex:1];
        if ([key isEqualToString:@"access_token"]) {
            _facebook.accessToken = value;
            [[NSUserDefaults standardUserDefaults] setObject:value forKey:FacebookTokenKey];
            NSLog(@"set facebook access token");

            // record the set of permissions we authorized with, in case we change them later
            NSArray *permissions = [[_apiSettings objectForKey:KGOSocialMediaTypeFacebook] objectForKey:@"permissions"];
            [[NSUserDefaults standardUserDefaults] setObject:permissions forKey:FacebookTokenPermissions];
            NSLog(@"stored facebook token permissions");
            
        } else if ([key isEqualToString:@"expires_in"]) {
            CGFloat interval = [value floatValue];
            NSDate *expiryDate = nil;
            if (!interval) {
                expiryDate = [NSDate distantFuture];
            } else {
                expiryDate = [NSDate dateWithTimeIntervalSinceNow:interval];
            }
            _facebook.expirationDate = expiryDate;
            [[NSUserDefaults standardUserDefaults] setObject:expiryDate forKey:FacebookTokenExpirationSetting];
            NSLog(@"set facebook expiration date");
        }
    }
    [[NSUserDefaults standardUserDefaults] synchronize];

    if ([self isFacebookLoggedIn]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:FacebookDidLoginNotification object:self];
    }
}

- (void)startupFacebook {
    _facebookStartupCount++;
    
    // prep for modules that actually use facebook API's
    if (!_fbRequestQueue)
        _fbRequestQueue = [[NSMutableArray alloc] init];
    if (!_fbRequestIdentifiers)
        _fbRequestIdentifiers = [[NSMutableArray alloc] init];
    if (!_fbUploadQueue)
        _fbUploadQueue = [[NSMutableArray alloc] init];
    if (!_fbUploadData)
        _fbUploadData = [[NSMutableArray alloc] init];
    
    if (!_facebook) {
        NSLog(@"starting up facebook");
		NSString *facebookAppID = [[_appConfig objectForKey:KGOSocialMediaTypeFacebook] objectForKey:@"AppID"];
        _facebook = [[Facebook alloc] initWithAppId:facebookAppID];
        
        NSDate *validDate = [[NSUserDefaults standardUserDefaults] objectForKey:FacebookTokenExpirationSetting];
        if ([validDate timeIntervalSinceNow] < 0) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:FacebookTokenKey];
        } else {
            NSArray *storedPermissions = [[NSUserDefaults standardUserDefaults] objectForKey:FacebookTokenPermissions];
            NSArray *neededPermissions = [[_apiSettings objectForKey:KGOSocialMediaTypeFacebook] objectForKey:@"permissions"];
            NSSet *storedSet = [NSSet setWithArray:storedPermissions];
            NSSet *neededSet = [NSSet setWithArray:neededPermissions];
            if ([storedSet isEqualToSet:neededSet]) {
                NSLog(@"%@ %@", [[NSUserDefaults standardUserDefaults] objectForKey:FacebookTokenKey], validDate);
                
                _facebook.accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:FacebookTokenKey];
                _facebook.expirationDate = validDate;
            }
        }
    } else {
        NSLog(@"facebook already started");
    }
    
    if ([self isFacebookLoggedIn]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:FacebookDidLoginNotification object:self];
    }
}

- (void)shutdownFacebook {
    if (_facebookStartupCount > 0)
        _facebookStartupCount--;
    
    if (_facebookStartupCount <= 0) {
        NSLog(@"shutting down facebook");
        for (FBRequest *aRequest in _fbRequestQueue) {
            aRequest.delegate = nil;
            [_fbRequestQueue removeObject:aRequest];
        }
        [_fbRequestQueue release];
        [_fbRequestIdentifiers release];
        [_fbUploadQueue release];
        [_fbUploadData release];

        if (_facebook) {
            [_facebook release];
            _facebook = nil;
        }
    }
}

- (void)shareOnFacebook:(NSString *)attachment prompt:(NSString *)prompt {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:attachment forKey:@"attachment"];

	if (prompt) {
		[params setObject:prompt forKey:@"user_message_prompt"];
	}

    [self startupFacebook];
    [_facebook dialog:@"feed" andParams:params andDelegate:self];
}

- (void)loginFacebook {
    
	if ([_facebook isSessionValid]) {
        NSLog(@"already have session");
		
	} else {
        NSArray *permissions = [[_apiSettings objectForKey:KGOSocialMediaTypeFacebook] objectForKey:@"permissions"];
        NSLog(@"asking for permission: %@", [permissions description]);
		[_facebook authorize:permissions delegate:self];
	}
}

- (void)logoutFacebook {
    if (_facebook) {
        [_facebook logout:self];
    }
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:FacebookTokenPermissions];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:FacebookTokenExpirationSetting];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:FacebookTokenKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:FacebookUsernameKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:FacebookDidLogoutNotification object:self];
}

- (NSString *)fbToken {
    return _facebook.accessToken;
}

- (void)setFbToken:(NSString *)aToken {
    _facebook.accessToken = aToken;
}

- (Facebook *)facebook {
    return _facebook;
}

#pragma mark Facebook - FBSessionDelegate

/**
 * Called when the user has logged in successfully.
 */
- (void)fbDidLogin {
    NSLog(@"facebook logged in!");
}

/**
 * Called when the user canceled the authorization dialog.
 */
-(void)fbDidNotLogin:(BOOL)cancelled {
    NSLog(@"failed to log in to facebook");
}

/**
 * Called when the request logout has succeeded.
 */
- (void)fbDidLogout {
	//[self.facebookDelegate facebookDidLogout];
    [[NSNotificationCenter defaultCenter] postNotificationName:FacebookDidLoginNotification object:self];
}

#pragma mark Facebook - FBRequestDelegate

/**
 * Called when the Facebook API request has returned a response. This callback
 * gives you access to the raw response. It's called before
 * (void)request:(FBRequest *)request didLoad:(id)result,
 * which is passed the parsed response object.
 */
- (void)request:(FBRequest *)request didReceiveResponse:(NSURLResponse *)response {
    DLog(@"received response for %@", [request description]);
}

#pragma mark Facebook - FBDialogDelegate

// these two methods are called at the very end of the FBDialog chain.
// other success/error messages may be sent before these.

- (void)dialogDidComplete:(FBDialog *)dialog {
    DLog(@"published successfully");
    [self shutdownFacebook];
}

- (void)dialogDidNotComplete:(FBDialog *)dialog {
    [self shutdownFacebook];
}

@end

