#import "KGOSocialMediaController.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "Foundation+KGOAdditions.h"
#import "JSON.h"
#import "BitlyWrapperDelegate.h"

#import "KGOSocialMediaService.h"

NSString * const KGOSocialMediaTypeFacebook = @"Facebook";
NSString * const KGOSocialMediaTypeTwitter = @"Twitter";
NSString * const KGOSocialMediaTypeEmail = @"Email";
NSString * const KGOSocialMediaTypeBitly = @"bit.ly";
NSString * const KGOSocialMediaTypeFoursquare = @"foursquare";

// Notification names
NSString * const TwitterDidLoginNotification = @"TwitterLoggedIn";
NSString * const TwitterDidLogoutNotification = @"TwitterLoggedOut";

NSString * const FacebookDidLoginNotification = @"FBDidLogin";
NSString * const FacebookDidLogoutNotification = @"FBDidLogout";

NSString * const FoursquareDidLoginNotification = @"foursquareDidLogin";
NSString * const FoursquareDidLogoutNotification = @"foursquareDidLogout";


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
    id<KGOSocialMediaService> service = [self serviceWithType:mediaType];
    if ([service respondsToSelector:@selector(addOptions:forSetting:)]) {
        [service addOptions:options forSetting:setting];
    }
}

+ (KGOFacebookService *)facebookService
{
    return (KGOFacebookService *)[[KGOSocialMediaController sharedController] serviceWithType:KGOSocialMediaTypeFacebook];
}

+ (KGOTwitterService *)twitterService
{
    return (KGOTwitterService *)[[KGOSocialMediaController sharedController] serviceWithType:KGOSocialMediaTypeTwitter];
}

+ (KGOFoursquareService *)foursquareService
{
    return (KGOFoursquareService *)[[KGOSocialMediaController sharedController] serviceWithType:KGOSocialMediaTypeFoursquare];
}

- (id<KGOSocialMediaService>)serviceWithType:(NSString *)type
{
    if (!_startedServices) {
        _startedServices = [[NSMutableDictionary alloc] init];
    }
    
    id<KGOSocialMediaService> service = [_startedServices objectForKey:type];
    if (!service) {
        NSDictionary *config = [_appConfig dictionaryForKey:type];
        if (config) {
            if ([type isEqualToString:KGOSocialMediaTypeFacebook]) {
                service = [[[KGOFacebookService alloc] initWithConfig:config] autorelease];
            } else if ([type isEqualToString:KGOSocialMediaTypeTwitter]) {
                service = [[[KGOTwitterService alloc] initWithConfig:config] autorelease];
            } else if ([type isEqualToString:KGOSocialMediaTypeFoursquare]) {
                service = [[[KGOFoursquareService alloc] initWithConfig:config] autorelease];
            }
            
            if (service) {
                [_startedServices setObject:service forKey:type];
            }
        }
    }
    
    return service;
}

- (void)removeServiceWithType:(NSString *)type
{
    [_startedServices removeObjectForKey:type];
}

- (id)init {
    self = [super init];
    if (self) {
        NSDictionary *infoDict = [KGO_SHARED_APP_DELEGATE() appConfig];
		_appConfig = [[infoDict objectForKey:KGOAppConfigKeySocialMedia] retain];
	}
	return self;
}

- (void)dealloc {
    [_startedServices release];
    
	[self shutdownBitly];
	
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
    NSString *appID = [facebookConfig nonemptyStringForKey:@"AppID"];
    return appID != nil;
}

- (BOOL)supportsTwitterSharing {
    Class cls = NSClassFromString (@"TWTweetComposeViewController");
    if (cls) {
        return ([_appConfig objectForKey:KGOSocialMediaTypeTwitter] != nil);
    } else {
        return NO;
    }
}

- (BOOL)supportsEmailSharing {
	return [_appConfig objectForKey:KGOSocialMediaTypeEmail] != nil;
}

- (BOOL)supportsBitlyURLShortening {
    NSDictionary *bitlyConfig = [_appConfig objectForKey:KGOSocialMediaTypeBitly];
    NSString *username = [bitlyConfig nonemptyStringForKey:@"Username"];
    return username != nil;
}

- (BOOL)supportsFoursquare {
    NSDictionary *foursquareConfig = [_appConfig objectForKey:KGOSocialMediaTypeFoursquare];
    NSString *clientID = [foursquareConfig nonemptyStringForKey:@"ClientID"];
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

// TODO: this and [KGOSocialMediaService serviceDisplayName] do the same thing
// except the latter doesn't have an email class.  decide which of these we
// want to keep around.
+ (NSString *)localizedNameForService:(NSString *)service
{
    if ([service isEqualToString:KGOSocialMediaTypeEmail]) {
        return NSLocalizedString(@"Email", nil);
        
    } else if ([service isEqualToString:KGOSocialMediaTypeFacebook]) {
        return NSLocalizedString(@"Facebook", nil);
        
    } else if ([service isEqualToString:KGOSocialMediaTypeTwitter]) {
        return NSLocalizedString(@"Twitter", nil);
        
    } else if ([service isEqualToString:KGOSocialMediaTypeFoursquare]) {
        return NSLocalizedString(@"foursquare", nil);
        
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
            NSString *shortURL = [urlData nonemptyStringForKey:@"url"];
			[self.bitlyDelegate didGetBitlyURL:shortURL];
        } else if ([self.bitlyDelegate respondsToSelector:@selector(failedToGetBitlyURL)]) {
            [self.bitlyDelegate failedToGetBitlyURL];
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

@end

