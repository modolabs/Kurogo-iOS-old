#import "JSONAPIRequest.h"
#import "MIT_MobileAppDelegate.h"
#import "JSON.h"

@interface JSONAPIRequest (Private)

+ (id)objectWithJSONString:(NSString *)jsonString;
- (void)safeReleaseSelf;
- (void)safeRetainSelf;

@end


@implementation JSONAPIRequest

@synthesize jsonDelegate, connectionWrapper, params, userData;

- (id)initWithJSONAPIDelegate:(id<JSONAPIDelegate>)delegate {
	if (self = [super init]) {
		jsonDelegate = [delegate retain];
        connectionWrapper = nil;
		userData = nil;
	}
	return self;
}

+ (JSONAPIRequest *)requestWithJSONAPIDelegate:(id<JSONAPIDelegate>)delegate {
	return [[[JSONAPIRequest alloc] initWithJSONAPIDelegate:delegate] autorelease];
}

- (void) dealloc
{
	connectionWrapper.delegate = nil;
    [connectionWrapper release];
	[jsonDelegate release];
    jsonDelegate = nil;
	self.userData = nil;
	[super dealloc];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([jsonDelegate conformsToProtocol:@protocol(UIAlertViewDelegate)]
        && [jsonDelegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)]) {
        [(id<UIAlertViewDelegate>)jsonDelegate alertView:alertView clickedButtonAtIndex:buttonIndex];
    }
    [self autorelease];
}

- (void)abortRequest {
	if (connectionWrapper != nil) {
		[connectionWrapper cancel];
		[((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]) hideNetworkActivityIndicator];
		self.connectionWrapper = nil;
        [self autorelease];
	}
}

- (BOOL)requestObjectFromModule:(NSString *)moduleName command:(NSString *)command parameters:(NSDictionary *)parameters {
	
	NSMutableDictionary *allParameters;
	if(parameters != nil) {
		allParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
	} else {
		allParameters = [NSMutableDictionary dictionary];
	}
	
	[allParameters setObject:moduleName	forKey:@"module"];
	[allParameters setObject:command forKey:@"command"];
	
	return [self requestObject:allParameters];
}
	
- (BOOL)requestObject:(NSDictionary *)parameters {
	return [self requestObject:parameters pathExtension:nil];
}

- (BOOL)requestObject:(NSDictionary *)parameters pathExtension:(NSString *)extendedPath {
    [self retain];
	
    self.params = parameters;
	
	NSString *path;
	if(extendedPath) {
		path = [MITMobileWebAPIURLString stringByAppendingString:extendedPath];
	} else {
		path = MITMobileWebAPIURLString;
	}
	
	NSAssert(!self.connectionWrapper, @"The connection wrapper is already in use");
	
	self.connectionWrapper = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
	BOOL requestSuccessfullyBegun = [connectionWrapper requestDataFromURL:[JSONAPIRequest buildURL:self.params queryBase:path]];

	[((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]) showNetworkActivityIndicator];
	
	if(!requestSuccessfullyBegun) {
		[self connection:self.connectionWrapper handleConnectionFailureWithError:nil];
	}
	return requestSuccessfullyBegun;
}

// TODO: general URL methods should go in a more general class
+ (NSString *)buildQuery:(NSDictionary *)dict {
	NSArray *keys = [dict allKeys];
	NSMutableArray *components = [NSMutableArray arrayWithCapacity:[keys count]];
	for (NSString *key in keys) {
		NSString *value = [[dict objectForKey:key] stringByReplacingOccurrencesOfString:@" " withString:@"+"];
		[components addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
	}
	return [components componentsJoinedByString:@"&"];
}

// internal method used to construct URL
+ (NSURL *)buildURL:(NSDictionary *)dict queryBase:(NSString *)base {
	NSString *urlString = [NSString stringWithFormat:@"%@?%@", base, [JSONAPIRequest buildQuery:dict]];	
	NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	return url;
}

#pragma mark ConnectionWrapper delegation

- (void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
    NSError *error = nil;
	id result = [JSONAPIRequest objectWithJSONData:data error:&error];
	if (error) {
		[self connection:wrapper handleConnectionFailureWithError:error];		
	} else if (!result) {
        error = [NSError errorWithDomain:JSONErrorDomain
                                    code:errJSONParseFailed
                                userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                          @"could not create an object from the result returned", @"message", nil]];
		[self connection:wrapper handleConnectionFailureWithError:error];		
    } else {
		[jsonDelegate request:self jsonLoaded:result];
		[((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]) hideNetworkActivityIndicator];
        self.connectionWrapper = nil;
        [self autorelease];
	}
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError: (NSError *)error {
	NSLog(@"Error: %@\ncode:%d\nuserinfo: %@\n%s", [error domain], [error code], [error userInfo], __PRETTY_FUNCTION__);
    
	[((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]) hideNetworkActivityIndicator];
    self.connectionWrapper = nil;

	if([jsonDelegate respondsToSelector:@selector(request:handleConnectionError:)]) {
		[jsonDelegate request:self handleConnectionError:error];
	}
    
    if (![self connection:wrapper shouldDisplayAlertForError:error]) {
        [self autorelease];
    }
}

- (void)connection:(ConnectionWrapper *)wrapper madeProgress:(CGFloat)progress {
    if ([jsonDelegate respondsToSelector:@selector(request:madeProgress:)]) {
        [jsonDelegate request:self madeProgress:progress];
    }
}

- (BOOL)connection:(ConnectionWrapper *)wrapper shouldDisplayAlertForError:(NSError *)error {
    BOOL shouldDisplay = NO;
    if ([jsonDelegate respondsToSelector:@selector(request:shouldDisplayAlertForError:)]) {
        shouldDisplay = [jsonDelegate request:self shouldDisplayAlertForError:error];
    }
    return shouldDisplay;
}

#pragma mark JSON object

+ (id)objectWithJSONString:(NSString *)jsonString error:(NSError **)error {
	if(![jsonString length]) {
		return nil;
	}
	
	SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
    id result = [jsonParser objectWithString:jsonString error:error];
    
    // if this is just a quoted string, wrap it in [] to make it an array and then parse to clean out escaped characters
    if (!result && jsonString && [[jsonString substringToIndex:1] isEqualToString:@"\""]) {
        jsonString = [NSString stringWithFormat:@"[%@]", jsonString];
        result = [jsonParser objectWithString:jsonString error:error];
        result = [((NSArray *)result) objectAtIndex:0];
    }
    
    [jsonParser release];
    
	return result;
}

+ (id)objectWithJSONData:(NSData *)jsonData error:(NSError **)error {
    NSString *jsonString = [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] autorelease];
    return [JSONAPIRequest objectWithJSONString:jsonString error:error];
}

+ (id)objectWithJSONData:(NSData *)jsonData {
    NSString *jsonString = [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] autorelease];
    return [JSONAPIRequest objectWithJSONString:jsonString error:NULL];
}

@end
