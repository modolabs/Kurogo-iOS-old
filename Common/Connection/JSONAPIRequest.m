#import "JSONAPIRequest.h"
#import "MIT_MobileAppDelegate.h"
#import "JSON.h"

@interface JSONAPIRequest (Private)

+ (id)objectWithJSONString:(NSString *)jsonString;

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
	DLog(@"Deallocating JSONAPIRequest."); 
	connectionWrapper.delegate = nil;
    [connectionWrapper release];
	[jsonDelegate release];
    jsonDelegate = nil;
	self.userData = nil;
	[super dealloc];
}

- (void)abortRequest {
	if (connectionWrapper != nil) {
		[((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]) hideNetworkActivityIndicator];
		[connectionWrapper cancel];
		self.connectionWrapper = nil;
	}
	[self release];
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
	[self retain]; // retain self until connection completes;
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

-(void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
	//DLog(@"Loaded data as string: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
    NSError *error = nil;
	id result = [JSONAPIRequest objectWithJSONData:data error:&error];
	if (error) {
		[self connection:wrapper handleConnectionFailureWithError:error];		
	} else {
		[((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]) hideNetworkActivityIndicator];
		[jsonDelegate request:self jsonLoaded:result];
        self.connectionWrapper = nil;
		[self release];		
	}
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError: (NSError *)error {
	[((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]) hideNetworkActivityIndicator];
	NSLog(@"Error: %@\ncode:%d\nuserinfo: %@\n%s", [error domain], [error code], [error userInfo], __PRETTY_FUNCTION__);
	
    self.connectionWrapper = nil;
    
	if([jsonDelegate respondsToSelector:@selector(handleConnectionFailureForRequest:)]) {
		[jsonDelegate handleConnectionFailureForRequest:self];
	}
	[self release];
}

- (void)connection:(ConnectionWrapper *)wrapper madeProgress:(CGFloat)progress {
    if ([jsonDelegate respondsToSelector:@selector(request:madeProgress:)]) {
        [jsonDelegate request:self madeProgress:progress];
    }
}

#pragma mark JSON object

+ (id)objectWithJSONString:(NSString *)jsonString error:(NSError **)error {
	if(![jsonString length]) {
		return nil;
	}
	
	SBJSON *jsonParser = [[SBJSON alloc] init];
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
