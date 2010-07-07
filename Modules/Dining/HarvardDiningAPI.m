
#import "HarvardDiningAPI.h"
//#import "MIT_MobileAppDelegate.h"
#import "JSONAPIRequest.h"
#import "Constants.h"


//#define HarvardDiningAPIURLString @"http://food.cs50.net/api/1.1/items?date="
#define HarvardDiningAPIURLString MITMobileWebAPIURLString

@implementation HarvardDiningAPI

@synthesize jsonDelegate, connectionWrapper;
@synthesize arrayData;

- (id) initWithJSONLoadedDelegate: (id<JSONLoadedDelegate>)delegate {
	if(self = [super init]) {
		jsonDelegate = [delegate retain];
        connectionWrapper = nil;
	}
	return self;
}

+ (HarvardDiningAPI *) jsonLoadedDelegate: (id<JSONLoadedDelegate>)delegate {
	return [[[self alloc] initWithJSONLoadedDelegate:delegate] autorelease];
}

- (void) dealloc
{
	connectionWrapper.delegate = nil;
    [connectionWrapper release];
	[jsonDelegate release];
    jsonDelegate = nil;
	[super dealloc];
}

-(void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
	id result = [JSONAPIRequest objectWithJSONData:data];
	if(result) {
//		[((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]) hideNetworkActivityIndicator];
		[jsonDelegate request:self jsonLoaded:result];
        self.connectionWrapper = nil;
			//[self release];	
	} else {
		NSError *error = [NSError errorWithDomain:@"JSONAPIRequest" code:0 
										 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"failed to handle JSON data", @"message", data, @"data", nil]];
		[self connection:wrapper handleConnectionFailureWithError:error];
	}
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError: (NSError *)error {
//	[((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]) hideNetworkActivityIndicator];
	
    self.connectionWrapper = nil;
	//NSLog(@"connection failed in %@, userinfo: %@, url: %@", [error domain], [error userInfo], wrapper.theURL);
    
	if([jsonDelegate respondsToSelector:@selector(handleConnectionFailureForRequest:)]) {
		[jsonDelegate handleConnectionFailureForRequest:self];
	}
	[self release];
}

- (void)abortRequest {
	if (connectionWrapper != nil) {
//		[((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]) hideNetworkActivityIndicator];
		[connectionWrapper cancel];
		self.connectionWrapper = nil;
	}
	[self release];
}

- (BOOL) requestObjectFromModule:(NSString *)moduleName command:(NSString *)command parameters:(NSDictionary *)parameters {
	
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

- (BOOL)requestObject:(NSDictionary *)parameters pathExtension: (NSString *)extendedPath {
	[self retain]; // retain self until connection completes;
	
	NSString *path;
	if(extendedPath) {
		path = [HarvardDiningAPIURLString stringByAppendingString:extendedPath];
	} else {
		path = HarvardDiningAPIURLString;
	}
	
	NSAssert(!self.connectionWrapper, @"The connection wrapper is already in use");
	
    // TODO: see if this needs and autorelease
	self.connectionWrapper = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
	BOOL requestSuccessfullyBegun = [connectionWrapper requestDataFromURL:[HarvardDiningAPI buildQuery:parameters queryBase:path]];
	
//	[((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]) showNetworkActivityIndicator];
	
	if(!requestSuccessfullyBegun) {
		[self connection:self.connectionWrapper handleConnectionFailureWithError:nil];
	}
	return requestSuccessfullyBegun;
}

// internal method used to construct URL
+(NSURL *)buildQuery:(NSDictionary *)dict queryBase:(NSString *)base {
	NSMutableString *urlString = [[NSMutableString alloc] initWithString:base];
	NSArray *keys = [dict allKeys];
	for (int i = 0; i < [dict count]; i++ ) {
		if (i == 0) {
			[urlString appendString:@"?"];
		} else {
			[urlString appendString:@"&"];
		}
		NSString *key = [keys objectAtIndex:i];
		[urlString appendString:[NSString stringWithFormat:@"%@=%@", key, [[dict objectForKey:key] stringByReplacingOccurrencesOfString:@" " withString:@"+"]]];
	}
	NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	[urlString release];
	return url;
}

-(NSArray *)returnReceivedData
{
	return self.arrayData;
}

@end
