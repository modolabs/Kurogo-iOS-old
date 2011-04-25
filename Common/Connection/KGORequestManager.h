#import <Foundation/Foundation.h>
#import "KGORequest.h"

@class Reachability;

@protocol KGORequestDelegate;

extern NSString * const HelloRequestDidCompleteNotification;
extern NSString * const KGODidLogoutNotification;
extern NSString * const KGODidLoginNotification;

// use this class to create requests Kurogo server.
// requests to facebook, bitly etc are handled by KGOSocialMediaController
@interface KGORequestManager : NSObject <KGORequestDelegate, UIAlertViewDelegate> {
    
    Reachability *_reachability;

    // the name of the server.
	NSString *_host;
    
    // the base URL of Kurogo. generally the same as _host, but if the entire
    // website is run out of a subdirectory, e.g. www.example.com/department,
    // in this case _host is www.example.com and _extendedHost is
    // www.example.com/department
    NSString *_extendedHost;
	NSString *_uriScheme; // http or https
	NSString *_accessToken;
	NSURL *_baseURL;

    KGORequest *_helloRequest;
    
    // login info
    KGORequest *_sessionRequest;
    KGORequest *_logoutRequest;
    NSDictionary *_sessionInfo;

    // push notification info
    KGORequest *_deviceRegistrationRequest;
    NSString *_devicePushID;
    NSString *_devicePushPassKey;
}

@property (nonatomic, retain) NSString *host;
@property (nonatomic, readonly) NSURL *hostURL;   // without path extension
@property (nonatomic, readonly) NSURL *serverURL; // with path extension

+ (KGORequestManager *)sharedManager;
- (BOOL)isReachable;

- (BOOL)isModuleAvailable:(NSString *)moduleTag;
- (BOOL)isModuleAuthorized:(NSString *)moduleTag;

- (KGORequest *)requestWithDelegate:(id<KGORequestDelegate>)delegate
                             module:(NSString *)module
                               path:(NSString *)path
                             params:(NSDictionary *)params;
- (void)showAlertForError:(NSError *)error;

#pragma mark -

- (void)requestServerHello;

#pragma mark Kurogo server login

- (BOOL)isUserLoggedIn;
- (void)requestSessionInfo;
- (void)loginKurogoServer;
- (void)logoutKurogoServer;
- (BOOL)requestingSessionInfo;

- (NSDictionary *)sessionInfo;

@property (nonatomic, retain) NSString *loginPath;

#pragma mark Push notification registration

- (void)registerNewDeviceToken;

// returned by Apple's push servers when we register.  nil if not available.
@property (nonatomic, retain) NSData *devicePushToken;
// device ID assigned by Kurogo server
@property (nonatomic, readonly) NSString *devicePushID;
// device pass key assigned by Kurogo server
@property (nonatomic, readonly) NSString *devicePushPassKey;

@end
