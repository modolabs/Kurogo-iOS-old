
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "ConnectionWrapper.h"

@class HarvardDiningAPI;

@protocol JSONLoadedDelegate <NSObject>
- (void)request:(HarvardDiningAPI *)request jsonLoaded:(id)JSONObject;

@optional 
- (void)handleConnectionFailureForRequest:(HarvardDiningAPI *)request;
@end


@interface HarvardDiningAPI : UIViewController <ConnectionWrapperDelegate> {
	id<JSONLoadedDelegate> jsonDelegate;
    ConnectionWrapper *connectionWrapper;
	
	NSArray *arrayData;
}

- (id) initWithJSONLoadedDelegate: (id<JSONLoadedDelegate>)delegate;

+ (HarvardDiningAPI *) jsonLoadedDelegate: (id<JSONLoadedDelegate>)delegate;

- (void)abortRequest;
- (BOOL)requestObjectFromModule:(NSString *)moduleName command:(NSString *)command parameters:(NSDictionary *)parameters;
- (BOOL)requestObject:(NSDictionary *)parameters;
- (BOOL)requestObject:(NSDictionary *)parameters pathExtension: (NSString *)extendedPath;
+ (NSURL *) buildQuery:(NSDictionary *)dict queryBase:(NSString *)base;

-(NSArray *)returnReceivedData;

@property (nonatomic, assign) id<JSONLoadedDelegate> jsonDelegate;
@property (nonatomic, retain) ConnectionWrapper *connectionWrapper;
@property (nonatomic, retain) NSArray *arrayData;


@end
