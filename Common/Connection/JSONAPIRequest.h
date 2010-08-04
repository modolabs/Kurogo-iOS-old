/* JSONAPIRequest.h
 *
 * Convenience class for making connections that expect responses in JSON format.
 */

#import <Foundation/Foundation.h>
#import "ConnectionWrapper.h"

@class JSONAPIRequest;

@protocol JSONAPIDelegate <NSObject>
- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)JSONObject;

@optional 
- (void)handleConnectionFailureForRequest:(JSONAPIRequest *)request;
- (void)request:(JSONAPIRequest *)request madeProgress:(CGFloat)progress;
@end


@interface JSONAPIRequest : NSObject <ConnectionWrapperDelegate> {
	id<JSONAPIDelegate> jsonDelegate;
    ConnectionWrapper *connectionWrapper;
	NSDictionary *params;
	id userData;
	BOOL haveRetainedSelf;
}

/* returns a new JSONAPIRequest object.
 */
- (id)initWithJSONAPIDelegate:(id<JSONAPIDelegate>)delegate;

/* returns an autoreleased JSONAPIRequest object (retained during the
 * connection and released after success or failure).
 * You should use this method instead of the -init method as the internals
 * of this class will manage its own retains/releases
 */
+ (JSONAPIRequest *)requestWithJSONAPIDelegate:(id<JSONAPIDelegate>)delegate;

/* cancel the request.
 * releases self when complete.
 */
- (void)abortRequest;

/* convenience method for API calls that take the form http://path.to.api?module=aModule&command=aCommand&a=1&b=2...
 * releases self when complete.
 */
- (BOOL)requestObjectFromModule:(NSString *)moduleName command:(NSString *)command parameters:(NSDictionary *)parameters;

/* convenience method for API calls that take the form http://path.to.api?a=1&b=2
 * releases self when complete.
 */
- (BOOL)requestObject:(NSDictionary *)parameters;

/* convenience method for API calls that take the form http://path.to.api/path/extension?a=1&b=2
 * releases self when complete.
 */
- (BOOL)requestObject:(NSDictionary *)parameters pathExtension: (NSString *)extendedPath;

/* constructs a query string according to rfc 1738, e.g. a=1&b=2
 */
+ (NSString *)buildQuery:(NSDictionary *)dict;

/* constructs a URL using dict as query parameters and base as the rest of the URL
 */
+ (NSURL *)buildURL:(NSDictionary *)dict queryBase:(NSString *)base;

/* wrapper method that gets a plist-compatible object from JSON data
 */
+ (id)objectWithJSONData:(NSData *)jsonData error:(NSError **)error;

// kept here for backwards compatibility -- delete when no longer used
+ (id)objectWithJSONData:(NSData *)jsonData;

@property (nonatomic, assign) id<JSONAPIDelegate> jsonDelegate;
@property (nonatomic, retain) ConnectionWrapper *connectionWrapper;
@property (nonatomic, retain) NSDictionary *params; // make it easy for creator to identify requests
@property (nonatomic, retain) id userData; // allow creator to add additional information to request

@end
