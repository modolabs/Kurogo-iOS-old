#import "MicroblogModule.h"

extern NSString * const FacebookGroupReceivedNotification;
extern NSString * const FacebookFeedDidUpdateNotification;

@interface FacebookModule : MicroblogModule {
    
    NSTimer *_statusPoller;
    NSArray *_latestFeedPosts;
    NSString *_gid;
    
    NSDate *_lastMessageDate;
    
}

// code from http://developer.apple.com/library/ios/#qa/qa2010/qa1480.html
// TODO: move this to Common if we find this format used in other places
+ (NSDate *)dateFromRFC3339DateTimeString:(NSString *)string;
+ (NSString *)agoStringFromDate:(NSDate *)date;

- (void)requestGroupOrStartPolling;
- (void)startPollingStatusUpdates;
- (void)stopPollingStatusUpdates;

- (void)requestStatusUpdates:(NSTimer *)aTimer;

- (void)didReceiveGroups:(id)result;
- (void)didReceiveFeed:(id)result;

- (void)facebookDidLogout:(NSNotification *)aNotification;
- (void)facebookDidLogin:(NSNotification *)aNotification;

@property(nonatomic, readonly) NSArray *latestFeedPosts;
@property(nonatomic, readonly) NSString *groupID;

@end
