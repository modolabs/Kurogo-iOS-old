#import <Foundation/Foundation.h>
#import "KGOWebViewController.h"

extern NSString * const FoursquareUsernameKey;

@class KGOFoursquareRequest;

@protocol KGOFoursquareRequestDelegate <NSObject>

- (void)foursquareRequest:(KGOFoursquareRequest *)request didSucceedWithResponse:(NSDictionary *)response;
- (void)foursquareRequest:(KGOFoursquareRequest *)request didFailWithError:(NSError *)error;

@end



typedef enum {
    FoursquareBroadcastLevelPrivate = 0,
    FoursquareBroadcastLevelPublic = 1 << 1,
    FoursquareBroadcastLevelTwitter = 1 << 2,
    FoursquareBroadcastLevelFacebook = 1 << 3
} FoursquareBroadcastLevel;



@interface KGOFoursquareRequest : NSObject {
    
    NSURLConnection *_connection;
    NSMutableData *_data;
    
    BOOL _isPostRequest;
    NSDictionary *_postParams;

}

- (void)requestFromURL:(NSString *)urlString;
- (void)connect;

- (NSString *)fullURLString;

@property(nonatomic) BOOL isPostRequest;
@property(nonatomic, retain) NSDictionary *postParams;
@property(nonatomic, retain) NSString *resourceName;
@property(nonatomic, retain) NSString *resourceID;
@property(nonatomic, retain) NSString *command;
@property(nonatomic, retain) NSDictionary *params;
@property(nonatomic, assign) id<KGOFoursquareRequestDelegate> delegate;

@end


@protocol KGOFoursquareCheckinDelegate <NSObject>

@optional

- (void)venueCheckinDidSucceed:(NSString *)venue;
- (void)venueCheckinDidFail:(NSString *)venue;
- (void)venueCheckinStatusReceived:(BOOL)status forVenue:(NSString *)venue;

- (void)didReceiveCheckins:(NSArray *)checkins total:(NSInteger)total forVenue:(NSString *)venue;

@end



@interface KGOFoursquareEngine : NSObject <KGOFoursquareRequestDelegate,
KGOWebViewControllerDelegate, UIAlertViewDelegate> {
    
    NSString *_oauthToken;
    KGOFoursquareRequest *_oauthRequest;
    KGOFoursquareRequest *_currentUserRequest;
    
    NSMutableArray *_checkinQueue;
    
    KGOWebViewController *_webVC;
}

@property(nonatomic, retain) NSString *clientID;
@property(nonatomic, retain) NSString *clientSecret;
@property(nonatomic, retain) NSString *authCode;

// in constructing this uri we require an instance of FoursquareModule with
// the tag "foursquare".  anything else will not work right now.
@property(nonatomic, retain) NSString *redirectURI;

- (KGOFoursquareRequest *)checkinRequestWithDelegate:(id<KGOFoursquareRequestDelegate>)delegate
                                               venue:(NSString *)venue
                                      broadcastLevel:(NSUInteger)level
                                             message:(NSString *)message;

- (KGOFoursquareRequest *)herenowRequestWithDelegate:(id<KGOFoursquareRequestDelegate>)delegate
                                               venue:(NSString *)venue;

- (KGOFoursquareRequest *)queryCheckinsRequestWithDelegate:(id<KGOFoursquareRequestDelegate>)delegate;

- (KGOFoursquareRequest *)requestWithDelegate:(id<KGOFoursquareRequestDelegate>)delegate;

// no message and broadcast "public"
- (void)checkinVenue:(NSString *)venue delegate:(id<KGOFoursquareCheckinDelegate>)delegate message:(NSString *)message;
- (void)checkUserStatusForVenue:(NSString *)venue delegate:(id<KGOFoursquareCheckinDelegate>)delegate;

- (void)disconnectRequestsForDelegate:(id<KGOFoursquareCheckinDelegate>)delegate;

- (void)authorize;
- (void)requestOAuthToken;
- (void)requestUserDetails;
- (void)logout;
- (BOOL)isLoggedIn;

@end
