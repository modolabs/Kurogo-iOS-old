#import <Foundation/Foundation.h>
#import "KGORequest.h"

@class Reachability;

@protocol KGORequestDelegate;

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

	NSDictionary *_apiVersionsByModule;
}

@property (nonatomic, retain) NSString *host;
@property (nonatomic, readonly) NSURL *hostURL;   // without path extension
@property (nonatomic, readonly) NSURL *serverURL; // with path extension

+ (KGORequestManager *)sharedManager;
- (BOOL)isReachable;
- (KGORequest *)requestWithDelegate:(id<KGORequestDelegate>)delegate module:(NSString *)module path:(NSString *)path params:(NSDictionary *)params;
- (void)showAlertForError:(NSError *)error;

// probably will modify these to take login creds
- (void)registerWithKGOServer;
- (void)authenticateWithKGOServer;

@end
