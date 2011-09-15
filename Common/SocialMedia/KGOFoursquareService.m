#import "KGOFoursquareService.h"
#import "KGOFoursquareEngine.h"
#import "Foundation+KGOAdditions.h"

@implementation KGOFoursquareService

- (void)didReceiveFoursquareAuthCode:(NSString *)code
{
    _foursquareEngine.authCode = code;
    [_foursquareEngine requestOAuthToken];
}

- (KGOFoursquareEngine *)foursquareEngine
{
    return _foursquareEngine;
}

- (void)dealloc
{
    [_foursquareEngine release];
    [_clientID release];
    [_clientSecret release];
    
    [super dealloc];
}

#pragma mark KGOSocialMediaService implementation

- (id)initWithConfig:(NSDictionary *)config
{
    self = [super init];
    if (self) {
        _clientID = [[config nonemptyStringForKey:@"ClientID"] retain];
        _clientSecret = [[config nonemptyStringForKey:@"ClientSecret"] retain];
    }
    return self;
}

- (void)startup {
    _foursquareStartupCount++;
    if (!_foursquareEngine) {
        _foursquareEngine = [[KGOFoursquareEngine alloc] init];
        _foursquareEngine.clientID = _clientID;
        _foursquareEngine.clientSecret = _clientSecret;
    }
}

- (void)shutdown
{
    if (_foursquareStartupCount > 0)
        _foursquareStartupCount--;
    if (_foursquareStartupCount <= 0) {
        [_foursquareEngine release];
        _foursquareEngine = nil;
    }
}

- (BOOL)isSignedIn
{
    return [_foursquareEngine isLoggedIn];
}

- (void)signin
{
    DLog(@"%@ %@", _foursquareEngine.clientSecret, _foursquareEngine.clientID);
    [_foursquareEngine authorize];
}

- (void)signout
{
    [_foursquareEngine logout];
}

- (NSString *)userDisplayName
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:FoursquareUsernameKey];
}

- (NSString *)serviceDisplayName
{
    return NSLocalizedString(@"foursquare", nil);
}

@end
