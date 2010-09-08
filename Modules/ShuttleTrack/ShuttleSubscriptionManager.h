
#import <Foundation/Foundation.h>
#import "JSONAPIRequest.h"


@class ShuttleStop;
@class ShuttleRoute;
//@class RouteStopSchedule;

@protocol ShuttleSubscriptionDelegate <NSObject>

- (void) subscriptionSucceededWithObject: (id)object;
- (void) subscriptionFailedWithObject: (id)object;

@end


@interface ShuttleSubscriptionManager : NSObject {
	NSDictionary *loadingSubscription;
}

+ (void)subscribeForRoute:(NSString *)routeID atStop:(NSString *)stopID scheduleTime:(NSDate *)time delegate: (id<ShuttleSubscriptionDelegate>)delegate object:(id)object;

+ (void)unsubscribeForRoute:(NSString *)routeID atStop:(NSString *)stopID delegate:(id<ShuttleSubscriptionDelegate>)delegate object:(id)object;

+ (BOOL)hasSubscription:(NSString *)routeID atStop:(NSString *)stopID scheduleTime:(NSDate *)time;

+ (void)addSubscriptionForRouteID:(NSString *)routeID atStopID:(NSString *)stopID startTime:(NSDate *)startTime endTime:(NSDate *)endTime;

+ (void)removeSubscriptionForRouteID:(NSString *)routeID atStopID:(NSString *)stopID;

+ (void)pruneSubscriptions;

@end

@interface SubscribeRequest : NSObject<JSONAPIDelegate>
{
	id object;
	id<ShuttleSubscriptionDelegate> delegate;
	NSString *routeID;
	NSString *stopID;
	//ShuttleRoute *route;
	//ShuttleStop *stop;
}

- (id)initWithDelegate:(id<ShuttleSubscriptionDelegate>)delegate routeID:(NSString *)routeID stopID:(NSString *)stopID object: (id)object;

@end

@interface UnsubscribeRequest : NSObject<JSONAPIDelegate>
{
	id object;
	id<ShuttleSubscriptionDelegate> delegate;
	NSString *routeID;
	NSString *stopID;
	//ShuttleRoute *route;
	//ShuttleStop *stop;
}

- (id)initWithDelegate:(id<ShuttleSubscriptionDelegate>)delegate routeID:(NSString *)routeID stopID:(NSString *)stopID object:(id)object;

@end
