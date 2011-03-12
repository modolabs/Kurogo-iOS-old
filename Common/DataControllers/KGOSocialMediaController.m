#import "KGOSocialMediaController.h"
#import "SFHFKeychainUtils.h"
#import "KGOAppDelegate.h"
#import "JSONAPIRequest.h"
#import "Foundation+KGOAdditions.h"

NSString * const KGOSocialMediaTypeFacebook = @"Facebook";
NSString * const KGOSocialMediaTypeTwitter = @"Twitter";
NSString * const KGOSocialMediaTypeEmail = @"Email";
NSString * const KGOSocialMediaTypeBitly = @"bit.ly";

static NSString * const TwitterUsernameKey = @"TwitterUsername";
static NSString * const TwitterServiceName = @"Twitter";

// NSUserDefaults
static NSString * const FacebookTokenKey = @"FBToken";
static NSString * const FacebookTokenPermissions = @"FBTokenPermissions";
static NSString * const FacebookTokenExpirationSetting = @"FBTokenExpiration";
static NSString * const FacebookDisplayNameKey = @"FBDisplayName";
// NSNotifications
NSString * const FacebookDidLoginNotification = @"FBDidLogin";
NSString * const FacebookDidLogoutNotification = @"FBDidLogout";



@interface FBRequestIdentifier : NSObject

@property (nonatomic, assign) SEL callback;
@property (nonatomic, assign) id receiver;

@end

@implementation FBRequestIdentifier

@synthesize callback, receiver;

@end


static KGOSocialMediaController *s_controller = nil;

@implementation KGOSocialMediaController

@synthesize twitterDelegate, bitlyDelegate;//, facebookDelegate;

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

- (NSArray *)allSupportedSharingTypes {
	return nil;
}

- (BOOL)supportsSharing {
	return [[self allSupportedSharingTypes] count] > 0;
}

- (BOOL)supportsFacebookSharing {
	return [_appConfig objectForKey:KGOSocialMediaTypeFacebook] != nil;
}

- (BOOL)supportsTwitterSharing {
	return [_appConfig objectForKey:KGOSocialMediaTypeTwitter] != nil;
}

- (BOOL)supportsEmailSharing {
	return [_appConfig objectForKey:KGOSocialMediaTypeEmail] != nil;
}

- (id)init {
    self = [super init];
    if (self) {
		NSString * file = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"];
        NSDictionary *infoDict = [NSDictionary dictionaryWithContentsOfFile:file];
		
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

#pragma mark -
#pragma mark bit.ly

- (void)getBitlyURLForLongURL:(NSString *)longURL delegate:(id<BitlyWrapperDelegate>)delegate {
	self.bitlyDelegate = delegate;

	NSString *username = [[_appConfig objectForKey:KGOSocialMediaTypeBitly] objectForKey:@"Username"];
	NSString *key = [[_appConfig objectForKey:KGOSocialMediaTypeBitly] objectForKey:@"APIKey"];

	[(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] showNetworkActivityIndicator];
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
		[_bitlyConnection release];
		_bitlyConnection = nil;
		[(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
	}
}

#pragma mark bit.ly - ConnectionWrapper

- (void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
    id jsonObj = [JSONAPIRequest objectWithJSONData:data];
    if (jsonObj && [jsonObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *urlData = [(NSDictionary *)jsonObj objectForKey:@"data"];
        if (urlData) {
            NSString *shortURL = [urlData objectForKey:@"url"];
			[self.bitlyDelegate didGetBitlyURL:shortURL];
        }
    }
    [_bitlyConnection release];
	_bitlyConnection = nil;
	[(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
}

- (BOOL)connection:(ConnectionWrapper *)connection shouldDisplayAlertForError:(NSError *)error {
    return YES;
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError:(NSError *)error {
	if (wrapper == _bitlyConnection) {
		[_bitlyConnection release];
		_bitlyConnection = nil;
		if ([self.bitlyDelegate respondsToSelector:@selector(failedToGetBitlyURL)]) {
			[self.bitlyDelegate failedToGetBitlyURL];
		}
	}
	[(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
}

#pragma mark -
#pragma mark Twitter

// these are just standard HTTP response codes,
// but some may be accompanied with an additional message that we may eventually want to distinguish.
// http://apiwiki.twitter.com/w/page/22554652/HTTP-Response-Codes-and-Errors
#define TwitterResponseCodeUnauthorized 401

- (void)startupTwitter {
	if (!_twitterEngine) {
		_twitterEngine = [[MGTwitterEngine alloc] initWithDelegate:self];
		NSString *key = [[_appConfig objectForKey:KGOSocialMediaTypeTwitter] objectForKey:@"OAuthConsumerKey"];
		NSString *secret = [[_appConfig objectForKey:KGOSocialMediaTypeTwitter] objectForKey:@"OAuthConsumerSecret"];
		[_twitterEngine setConsumerKey:key secret:secret];
	}
}

- (void)shutdownTwitter {
	self.twitterDelegate = nil;
	if (_twitterEngine) {
        [_twitterEngine closeAllConnections];
		[_twitterEngine release];
		_twitterEngine = nil;
	}
}

- (void)loginTwitterWithDelegate:(id<TwitterWrapperDelegate>)delegate {
	self.twitterDelegate = delegate;
	[self startupTwitter];
	
	NSString *username = [self twitterUsername];
	if (!username) {
		[self.twitterDelegate promptForTwitterLogin];
		return;
	}
	
	NSError *error = nil;
	NSString *password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:TwitterServiceName error:&error];
	if (error) {
		NSLog(@"something went wrong looking up access token, error=%@", error);
		[self.twitterDelegate twitterFailedToLogin];
		return;
	}
	
	[_twitterEngine getXAuthAccessTokenForUsername:username password:password];
}

- (void)loginTwitterWithUsername:(NSString *)username password:(NSString *)password {
	[(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] showNetworkActivityIndicator];
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
	
	[self.twitterDelegate twitterDidLogout];
}

- (void)postToTwitter:(NSString *)text {
	[_twitterEngine sendUpdate:text];
}

- (void)getPostsForTwitterHashtag:(NSString *)hashtag {
    if ([hashtag rangeOfString:@"#"].location != 0) {
        hashtag = [NSString stringWithFormat:@"#%@", hashtag];
    }
    //[_twitterEngine
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
    
	[(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
	
	if (!error) {
		[[NSUserDefaults standardUserDefaults] setObject:_twitterUsername forKey:TwitterUsernameKey];
		[self.twitterDelegate twitterDidLogin];
	} else {
		NSLog(@"error on saving token=%@", [error description]);
	}
}

- (void)requestSucceeded:(NSString *)connectionIdentifier {
	[(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
	[self.twitterDelegate twitterRequestSucceeded:connectionIdentifier];
}

- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error {
	[(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
	
	NSString *errorTitle;
	NSString *errorMessage;
	
	if (error.code == TwitterResponseCodeUnauthorized) {
		errorTitle = NSLocalizedString(@"Login failed", nil);
		errorMessage = NSLocalizedString(@"Twitter username and password is not recognized", nil);
		
		[self logoutTwitter];
		
	} else {
		errorTitle = NSLocalizedString(@"Network failed", nil);
		errorMessage = NSLocalizedString(@"Failure connecting to Twitter", nil);
	}
	
	UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:errorTitle 
														 message:errorMessage
														delegate:nil 
											   cancelButtonTitle:NSLocalizedString(@"OK", nil) 
											   otherButtonTitles:nil] autorelease];
	[alertView show];
}


- (void)connectionStarted:(NSString *)connectionIdentifier {
	[(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] showNetworkActivityIndicator];
}

- (void)connectionFinished:(NSString *)connectionIdentifier {
	[(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
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

    if ([self facebookDisplayName]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:FacebookDidLoginNotification object:self];
    }
}

- (void)startupFacebook {
    _facebookStartupCount++;
    
    if (!_facebook) {
        NSLog(@"starting up facebook");
		NSString *facebookAppID = [[_appConfig objectForKey:KGOSocialMediaTypeFacebook] objectForKey:@"AppID"];
        _facebook = [[Facebook alloc] initWithAppId:facebookAppID];
        _fbRequestQueue = [[NSMutableArray alloc] init];
        _fbRequestIdentifiers = [[NSMutableArray alloc] init];
        
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
    
    // if we want to add an arbitrary list of links, do something like the following:
    /*
     NSDictionary* actionLinks = [NSArray arrayWithObjects:
     [NSDictionary dictionaryWithObjectsAndKeys:@"Always Running",@"text",@"http://itsti.me/",@"href", nil],
     nil];
     [params setObject:actionLinks forKey:@"action_links"];
     */    
    
    [_facebook dialog:@"feed" andParams:params andDelegate:self];
}

//- (void)loginFacebookWithDelegate:(id<FacebookWrapperDelegate>)delegate {
- (void)loginFacebook {
	//self.facebookDelegate = delegate;
    
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

- (NSString *)facebookDisplayName {
    NSString *displayName = [[NSUserDefaults standardUserDefaults] stringForKey:FacebookDisplayNameKey];
    NSLog(@"cached facebook displayname: %@", displayName);
    if (displayName && [_facebook isSessionValid]) {
        return displayName;
    } else if ([_facebook isSessionValid]) {
        if (!_fbSelfRequest) {
            NSLog(@"getting facebook profile info");
            _fbSelfRequest = [self requestFacebookGraphPath:@"me" receiver:self callback:@selector(didReceiveSelfInfo:)];
        }
        return nil;
    } else {
        NSLog(@"displayname = %@, facebook session invalid", displayName);
        [self loginFacebook];
        return nil;
    }
}

#pragma mark Facebook request wrappers

- (FBRequest *)requestFacebookGraphPath:(NSString *)graphPath receiver:(id)receiver callback:(SEL)callback {
    DLog(@"requesting graph path: %@", graphPath);
    FBRequest *request = nil;
    if ([receiver respondsToSelector:callback]) {
        FBRequestIdentifier *identifier = [[[FBRequestIdentifier alloc] init] autorelease];
        identifier.receiver = receiver;
        identifier.callback = callback;
        [_fbRequestIdentifiers addObject:identifier];
        
        request = [_facebook requestWithGraphPath:graphPath andDelegate:self];
        [request connect];
        [_fbRequestQueue addObject:request];
    }
    return request;
}

- (FBRequest *)requestFacebookFQL:(NSString *)query receiver:(id)receiver callback:(SEL)callback {
    DLog(@"requesting FQL: %@", query);
    FBRequest *request = nil;
    if ([receiver respondsToSelector:callback]) {
        FBRequestIdentifier *identifier = [[[FBRequestIdentifier alloc] init] autorelease];
        identifier.receiver = receiver;
        identifier.callback = callback;
        [_fbRequestIdentifiers addObject:identifier];
        
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:query forKey:@"query"];
        request = [_facebook requestWithMethodName:@"fql.query" andParams:params andHttpMethod:@"GET" andDelegate:self];
        [request connect];
        [_fbRequestQueue addObject:request];
    }
    return request;
}

- (void)didReceiveSelfInfo:(id)result {
    _fbSelfRequest.delegate = nil;
    _fbSelfRequest = nil;
    
    NSString *name = [result stringForKey:@"name" nilIfEmpty:YES];
    if (name) {
        [[NSUserDefaults standardUserDefaults] setObject:name forKey:FacebookDisplayNameKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:FacebookDidLoginNotification object:self];
    }
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
    NSLog(@"received response for %@", [request description]);
}

/**
 * Called when a request returns and its response has been parsed into an object.
 * The resulting object may be a dictionary, an array, a string, or a number, depending
 * on the format of the API response.
 * If you need access to the raw response, use
 * (void)request:(FBRequest *)request didReceiveResponse:(NSURLResponse *)response.
 */
- (void)request:(FBRequest *)request didLoad:(id)result {
    NSLog(@"%@", [request.url description]);
    NSLog(@"%@", [request.params description]);
    NSLog(@"%@", [result description]);
    NSInteger index = [_fbRequestQueue indexOfObject:request];
    
    if (index != NSNotFound) {
        FBRequestIdentifier *identifier = [_fbRequestIdentifiers objectAtIndex:index];
        [identifier.receiver performSelector:identifier.callback withObject:result];
        [_fbRequestQueue removeObjectAtIndex:index];
        [_fbRequestIdentifiers removeObjectAtIndex:index];
    }
}

- (void)disconnectFacebookRequests:(id)receiver {
    NSArray *identifiers = [[_fbRequestIdentifiers copy] autorelease];
    for (FBRequestIdentifier *anIdentifier in identifiers) {
        if (anIdentifier.receiver == receiver) {
            anIdentifier.receiver = nil;
            NSInteger index = [_fbRequestIdentifiers indexOfObject:anIdentifier];
            if (index != NSNotFound) {
                FBRequest *request = [_fbRequestQueue objectAtIndex:index];
                request.delegate = nil;
                [_fbRequestIdentifiers removeObjectAtIndex:index];
                [_fbRequestQueue removeObjectAtIndex:index];
            }
        }
    }
}

/**
 * Called when an error prevents the Facebook API request from completing successfully.
 */
- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    DLog(@"%@", [error description]);
    NSDictionary *userInfo = [error userInfo];
    if ([[userInfo stringForKey:@"type" nilIfEmpty:YES] isEqualToString:@"OAuthException"]) {
        [self logoutFacebook];
    }
}

#pragma mark Facebook - FBDialogDelegate

/**
 * Called when a UIServer Dialog successfully return.
 */
- (void)dialogDidComplete:(FBDialog *)dialog {
    DLog(@"published successfully");
}

@end

