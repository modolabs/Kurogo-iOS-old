#import "FacebookModule.h"
#import "FacebookPhotosViewController.h"
#import "KGOSocialMediaController.h"
#import "KGOHomeScreenWidget.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"
#import "Foundation+KGOAdditions.h"
#import "FacebookUser.h"

static NSString * const FacebookGroupKey = @"FBGroup";

NSString * const FacebookGroupReceivedNotification = @"FBGroupReceived";
NSString * const FacebookFeedDidUpdateNotification = @"FBFeedReceived";

@interface FacebookModule (Private)

- (void)setupPolling;
- (void)shutdownPolling;

@end

@implementation FacebookModule

// code from http://developer.apple.com/library/ios/#qa/qa2010/qa1480.html
+ (NSDate *)dateFromRFC3339DateTimeString:(NSString *)rfc3339DateTimeString {
    static NSDateFormatter *    sRFC3339DateFormatter;
    NSDate *                    date;
    
    // If the date formatters aren't already set up, do that now and cache them 
    // for subsequence reuse.
    
    if (sRFC3339DateFormatter == nil) {
        NSLocale *                  enUSPOSIXLocale;
        
        sRFC3339DateFormatter = [[NSDateFormatter alloc] init];
        assert(sRFC3339DateFormatter != nil);
        
        enUSPOSIXLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
        assert(enUSPOSIXLocale != nil);
        
        [sRFC3339DateFormatter setLocale:enUSPOSIXLocale];
        [sRFC3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"];
        [sRFC3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    
    // Convert the RFC 3339 date time string to an NSDate.
    date = [sRFC3339DateFormatter dateFromString:rfc3339DateTimeString];
    return date;
}

+ (NSString *)agoStringFromDate:(NSDate *)date {
    NSString *result = nil;
    double minutes = -[date timeIntervalSinceNow] / 60;
    if (minutes < 60) {
        result = [NSString stringWithFormat:@"%.0f %@", minutes, NSLocalizedString(@"minutes ago", nil)];
    } else {
        double hours = minutes / 60;
        if (hours < 24) {
            result = [NSString stringWithFormat:@"%.0f %@", hours, NSLocalizedString(@"hours ago", nil)];
        } else {
            double days = hours / 24;
            result = [NSString stringWithFormat:@"%.0f %@", days, NSLocalizedString(@"days ago", nil)];
        }
    }
    return result;
}

#pragma mark polling

- (void)setupPolling {
    NSLog(@"setting up polling...");
    if (![[KGOSocialMediaController sharedController] isFacebookLoggedIn]) {
        NSLog(@"waiting for facebook to log in...");
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(facebookDidLogin:)
                                                     name:FacebookDidLoginNotification
                                                   object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(facebookDidLogout:)
                                                     name:FacebookDidLogoutNotification
                                                   object:nil];
        [self requestGroupOrStartPolling];
    }
}

- (void)shutdownPolling {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopPollingStatusUpdates];
}

- (void)startPollingStatusUpdates {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideChatBubble:)
                                                 name:TwitterStatusDidUpdateNotification
                                               object:nil];
    
    [self requestStatusUpdates:nil];
    
    if (!_statusPoller) {
        NSLog(@"scheduling timer...");
        NSTimeInterval interval = 15;
        _statusPoller = [[NSTimer timerWithTimeInterval:interval
                                                 target:self
                                               selector:@selector(requestStatusUpdates:)
                                               userInfo:nil
                                                repeats:YES] retain];
        [[NSRunLoop currentRunLoop] addTimer:_statusPoller forMode:NSDefaultRunLoopMode];
    }
}

- (void)stopPollingStatusUpdates {
    if (_statusPoller) {
        [_statusPoller invalidate];
        [_statusPoller release];
        _statusPoller = nil;
    }
}

- (void)requestStatusUpdates:(NSTimer *)aTimer {
    NSLog(@"requesting status update");
    
    NSString *feedPath = [NSString stringWithFormat:@"%@/feed", _gid];
    [[KGOSocialMediaController sharedController] requestFacebookGraphPath:feedPath
                                                                 receiver:self
                                                                 callback:@selector(didReceiveFeed:)];
    
    
}

#pragma mark facebook connection

- (void)requestGroupOrStartPolling {
    _lastMessageDate = [[NSDate distantPast] retain];
    
    if (!_gid) {
        NSLog(@"requesting groups");
        [[KGOSocialMediaController sharedController] requestFacebookGraphPath:@"me/groups"
                                                                     receiver:self
                                                                     callback:@selector(didReceiveGroups:)];
    } else {
        [self startPollingStatusUpdates];
    }
}

- (void)facebookDidLogin:(NSNotification *)aNotification
{
    NSLog(@"facebook logged in");
    [self requestGroupOrStartPolling];
}

- (void)facebookDidLogout:(NSNotification *)aNotification
{
    [_gid release];
    _gid = nil;
    
    [_latestFeedPosts release];
    _latestFeedPosts = nil;
    
    [self shutdownPolling];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:FacebookGroupKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)groupID {
    return _gid;
}

- (void)didReceiveGroups:(id)result {
    NSArray *data = [result arrayForKey:@"data"];
    for (id aGroup in data) {
        // TODO: get group names from server
        if ([[aGroup objectForKey:@"name"] isEqualToString:@"Modo Labs UX"]) {

            [_gid release];
            _gid = [[aGroup objectForKey:@"id"] retain];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:FacebookGroupReceivedNotification object:self];

            [[NSUserDefaults standardUserDefaults] setObject:_gid forKey:FacebookGroupKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self startPollingStatusUpdates];
        }
    }
}

- (NSArray *)latestFeedPosts {
    return _latestFeedPosts;
}

- (void)didReceiveFeed:(id)result {
    NSArray *data = [result arrayForKey:@"data"];
    if (data) {
        [_latestFeedPosts release];
        _latestFeedPosts = [data retain];
        
        for (NSDictionary *aPost in _latestFeedPosts) {
            NSString *type = [aPost stringForKey:@"type" nilIfEmpty:YES];
            if ([type isEqualToString:@"status"]) {
                NSString *message = [aPost stringForKey:@"message" nilIfEmpty:YES];
                
                NSDictionary *from = [aPost dictionaryForKey:@"from"];
                FacebookUser *user = [FacebookUser userWithDictionary:from];
                
                NSDate *lastUpdate = nil;
                NSString *dateString = [aPost stringForKey:@"updated_time" nilIfEmpty:YES];
                if (dateString) {
                    lastUpdate = [FacebookModule dateFromRFC3339DateTimeString:dateString];
                }
                
                // TODO: if we confirm that this is later than the twitter update, hide twitter's chatbubble
                if (lastUpdate && [lastUpdate compare:_lastMessageDate] == NSOrderedDescending) {
                    [_lastMessageDate release];
                    _lastMessageDate = [lastUpdate retain];

                    self.chatBubble.hidden = NO;
                    self.chatBubbleSubtitleLabel.text = [NSString stringWithFormat:
                                                         @"%@ %@", user.name,
                                                         [FacebookModule agoStringFromDate:_lastMessageDate]];
                    self.chatBubbleTitleLabel.text = message;
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:FacebookStatusDidUpdateNotification object:nil];

                    break;
                }
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:FacebookFeedDidUpdateNotification object:self];
    }
}

#pragma mark -

- (id)initWithDictionary:(NSDictionary *)moduleDict {
    self = [super initWithDictionary:moduleDict];
    if (self) {
        self.buttonImage = [UIImage imageWithPathName:@"modules/facebook/button-facebook.png"];
        self.labelText = @"Harvard-Radcliffe Reunion";
        self.chatBubbleCaratOffset = 0.75;
    }
    return self;
}

- (NSArray *)objectModelNames {
    return [NSArray arrayWithObject:@"FacebookModel"];
}

#pragma mark -

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [[[FacebookPhotosViewController alloc] init] autorelease];
    }
    return vc;
}
/*
- (void)launch {
    [super launch];
    [[KGOSocialMediaController sharedController] startupFacebook];
    [self setupPolling];
}


- (void)terminate {
    [super terminate];
    [[KGOSocialMediaController sharedController] shutdownFacebook];
    [self shutdownPolling];
}
*/
- (void)applicationDidFinishLaunching {
    [[KGOSocialMediaController sharedController] startupFacebook];
    _gid = [[[NSUserDefaults standardUserDefaults] objectForKey:FacebookGroupKey] retain];
    NSLog(@"stored group id is %@", _gid);
    [self setupPolling];
}

- (void)applicationWillTerminate {
    [[KGOSocialMediaController sharedController] shutdownFacebook];
    [self shutdownPolling];
}

- (void)applicationDidEnterBackground {
    [self shutdownPolling];
}

- (void)applicationWillEnterForeground {
    [self setupPolling];
}

#pragma mark View on home screen

- (KGOHomeScreenWidget *)buttonWidget {
    KGOHomeScreenWidget *widget = [super buttonWidget];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        widget.gravity = KGOLayoutGravityBottomRight;
    }
    return widget;
}

#pragma mark Social media controller

- (NSSet *)socialMediaTypes {
    return [NSSet setWithObject:KGOSocialMediaTypeFacebook];
}

- (NSDictionary *)userInfoForSocialMediaType:(NSString *)mediaType {
    if ([mediaType isEqualToString:KGOSocialMediaTypeFacebook]) {
        return [NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:
                                                   @"read_stream",
                                                   @"offline_access",
                                                   @"user_groups",
                                                   nil]
                                           forKey:@"permissions"];
    }
    return nil;
}

@end
