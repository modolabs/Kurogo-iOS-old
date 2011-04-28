#import "KGOFacebookService.h"
#import "Foundation+KGOAdditions.h"
#import "KGOSocialMediaController.h"

// NSUserDefaults
static NSString * const FacebookTokenKey = @"FBToken";
static NSString * const FacebookTokenPermissions = @"FBTokenPermissions";
static NSString * const FacebookTokenExpirationSetting = @"FBTokenExpiration";

NSString * const FacebookUsernameKey = @"FBUsername";


@implementation KGOFacebookService

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
            NSArray *permissions = [_apiSettings objectForKey:@"permissions"];
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
    
    if ([self isSignedIn]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:FacebookDidLoginNotification object:self];
    }
}

- (void)dealloc
{
    [_appID release];
    [_facebook release];
    [_fbRequestQueue release];
    [_fbRequestIdentifiers release];
    [_fbUploadData release];
    [_fbUploadQueue release];
    [_apiSettings release];
    
    [super dealloc];
}

#pragma mark KGOSocialMediaService implementation

- (id)initWithConfig:(NSDictionary *)config
{
    self = [super init];
    if (self) {
        _appID = [[config stringForKey:@"AppID" nilIfEmpty:YES] retain];
    }
    return self;
}

- (NSString *)serviceDisplayName
{
    return NSLocalizedString(@"Facebook", @"display name for facebook third party service");
}

- (NSString *)userDisplayName
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:FacebookUsernameKey];
}

- (void)startup
{
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
        _facebook = [[Facebook alloc] initWithAppId:_appID];
        
        NSDate *validDate = [[NSUserDefaults standardUserDefaults] objectForKey:FacebookTokenExpirationSetting];
        if ([validDate timeIntervalSinceNow] < 0) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:FacebookTokenKey];
        } else {
            NSArray *storedPermissions = [[NSUserDefaults standardUserDefaults] objectForKey:FacebookTokenPermissions];
            NSArray *neededPermissions = [_apiSettings objectForKey:@"permissions"];
            NSSet *storedSet = [NSSet setWithArray:storedPermissions];
            NSSet *neededSet = [NSSet setWithArray:neededPermissions];
            if ([storedSet isEqualToSet:neededSet]) {
                DLog(@"%@ %@", [[NSUserDefaults standardUserDefaults] objectForKey:FacebookTokenKey], validDate);
                
                _facebook.accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:FacebookTokenKey];
                _facebook.expirationDate = validDate;
            }
        }
    } else {
        NSLog(@"facebook already started");
    }
    
    if ([self isSignedIn]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:FacebookDidLoginNotification object:self];
    }
}

- (void)shutdown
{
    if (_facebookStartupCount > 0)
        _facebookStartupCount--;
    
    if (_facebookStartupCount <= 0) {
        NSLog(@"shutting down facebook");
        [_fbRequestQueue enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [(FBRequest *)obj setDelegate:nil];
        }];
        
        [_fbRequestQueue release];
        _fbRequestQueue = nil;
        
        [_fbRequestIdentifiers release];
        _fbRequestIdentifiers = nil;
        
        [_fbUploadQueue release];
        _fbUploadQueue = nil;
        
        [_fbUploadData release];
        _fbUploadData = nil;
        
        if (_facebook) {
            [_facebook release];
            _facebook = nil;
        }
    }
}

- (BOOL)isSignedIn
{
    return [_facebook isSessionValid];
}

- (void)signin
{
	if ([_facebook isSessionValid]) {
        DLog(@"already have session");
		
	} else {
        NSArray *permissions = [_apiSettings objectForKey:@"permissions"];
        DLog(@"asking for permission: %@", [permissions description]);
		[_facebook authorize:permissions delegate:self];
	}
}

- (void)signout
{
    if (_facebook) {
        [_facebook logout:self];
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:FacebookTokenPermissions];
    [defaults removeObjectForKey:FacebookTokenExpirationSetting];
    [defaults removeObjectForKey:FacebookTokenKey];
    [defaults removeObjectForKey:FacebookUsernameKey];
    [defaults synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FacebookDidLogoutNotification object:self];
}

- (void)addOptions:(NSArray *)options forSetting:(NSString *)setting
{
    if (!_apiSettings) {
        _apiSettings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:options, setting, nil];
    } else {
        NSMutableArray *existingValues = [[[_apiSettings objectForKey:setting] mutableCopy] autorelease];
        if (existingValues) {
            [existingValues addObjectsFromArray:options];
            NSSet *uniqueValues = [NSSet setWithArray:existingValues];
            [_apiSettings setObject:[uniqueValues allObjects] forKey:setting];
        } else {
            [_apiSettings setObject:options forKey:setting];
        }
    }
}


#pragma mark Facebook - FBSessionDelegate

// called if user logs in successfully via pop-up dialog
// (3G or equivalent devices and lower)
- (void)fbDidLogin {
    DLog(@"facebook logged in!");
    [[NSNotificationCenter defaultCenter] postNotificationName:FacebookDidLoginNotification object:self];
}

/**
 * Called when the user canceled the authorization dialog.
 */
-(void)fbDidNotLogin:(BOOL)cancelled {
    NSLog(@"failed to log in to facebook");
    // TODO: decide if we want different behavior depending on whether user cancelled.
}

/**
 * Called when the request logout has succeeded.
 */
- (void)fbDidLogout {
    [[NSNotificationCenter defaultCenter] postNotificationName:FacebookDidLogoutNotification object:self];
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

#pragma mark Dialog

- (void)shareOnFacebook:(NSString *)attachment prompt:(NSString *)prompt {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:attachment forKey:@"attachment"];
    
	if (prompt) {
		[params setObject:prompt forKey:@"user_message_prompt"];
	}
    
    [self startup];
    [_facebook dialog:@"feed" andParams:params andDelegate:self];
}

// FBDialogDelegate
// these two methods are called at the very end of the FBDialog chain.
// other success/error messages may be sent before these.

- (void)dialogDidComplete:(FBDialog *)dialog {
    DLog(@"published successfully");
    [self shutdown];
}

- (void)dialogDidNotComplete:(FBDialog *)dialog {
    [self shutdown];
}

@end
