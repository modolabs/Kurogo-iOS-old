#import <Foundation/Foundation.h>

// blocks to operate on objects created from JSON in the background
// e.g. create core data objects
typedef NSInteger (^JSONObjectHandler)(id);

@class KGORequest;

@protocol KGORequestDelegate <NSObject>

/* notifies the receiver that this request is no longer self-retained.
 * because requests are self-retaining, delegates' dealloc methods must
 * ensure that all requests' delegates are set to nil, preferably
 * by calling -cancel to terminate the associated url connection.
 */
- (void)requestWillTerminate:(KGORequest *)request;

@optional

- (void)request:(KGORequest *)request didFailWithError:(NSError *)error;

// generally delegates implement exactly one of the following per request
- (void)request:(KGORequest *)request didHandleResult:(NSInteger)returnValue; // retValue could be number of records updated
- (void)request:(KGORequest *)request didReceiveResult:(id)result;

// for showing determinate loading indicators. progress is between 0 and 1
- (void)request:(KGORequest *)request didMakeProgress:(CGFloat)progress;
- (void)requestDidReceiveResponse:(KGORequest *)request;

@end

typedef enum {
	KGORequestResponseDictionary,
	KGORequestResponseArray,
	KGORequestResponseData
} KGORequestResponseType;


@interface KGORequest : NSObject {
	
	NSMutableData *_data;
	NSURLConnection *_connection;
    long long _contentLength;

	NSThread *_thread;
}

@property(nonatomic, retain) NSString *module;
@property(nonatomic, retain) NSString *path;
@property(nonatomic, retain) NSDictionary *getParams;
@property(nonatomic, retain) NSDictionary *postParams;

@property(nonatomic, retain) NSString *format; // default is json
@property(nonatomic) NSURLRequestCachePolicy cachePolicy; // default is NSURLRequestReloadIgnoringLocalAndRemoteCacheData
@property(nonatomic) NSTimeInterval timeout; // default is 30 seconds

@property(nonatomic) KGORequestResponseType expectedResponseType; // default is dictionary
@property(nonatomic, copy) JSONObjectHandler handler;

// urls are of the form
// https://<kurogo-server>/<module>/<path>?<key>=<value>
// https://kurogo.hq.modolabs.com/people/search?q=Some+Guy
// https://kurogo.hq.modolabs.com/hello? (special case)
@property(nonatomic, retain) NSURL *url;
@property(nonatomic, assign) id<KGORequestDelegate> delegate;

- (BOOL)connect;
- (void)cancel;  // call to stop receiving messages

@end


// use this class to create requests Kurogo server.
// requests to facebook, bitly etc are handled by KGOSocialMediaController
@interface KGORequestManager : NSObject <KGORequestDelegate, UIAlertViewDelegate> {

	NSString *_host;
	NSString *_uriScheme; // http or https
	NSString *_accessToken;
	NSURL *_baseURL;

	NSDictionary *_apiVersionsByModule;
}

@property (nonatomic, retain) NSString *host;

+ (KGORequestManager *)sharedManager;
- (KGORequest *)requestWithDelegate:(id<KGORequestDelegate>)delegate module:(NSString *)module path:(NSString *)path params:(NSDictionary *)params;
- (void)showAlertForError:(NSError *)error;

// probably will modify these to take login creds
- (void)registerWithKGOServer;
- (void)authenticateWithKGOServer;

@end


extern NSString * const KGORequestErrorDomain;
// wrapper for most common kCFURLError constants, plus custom states
// TODO: coordinate with server-side error messages and 
// HTTP status codes
typedef enum {
	KGORequestErrorBadRequest,
	KGORequestErrorForbidden,
	KGORequestErrorUnreachable,
	KGORequestErrorDeviceOffline,
	KGORequestErrorTimeout,
	KGORequestErrorBadResponse,
	KGORequestErrorVersionMismatch,
	KGORequestErrorInterrupted,
	KGORequestErrorServerMessage,
	KGORequestErrorOther
} KGORequestErrorCode;
