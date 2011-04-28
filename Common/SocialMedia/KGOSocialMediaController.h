#import <Foundation/Foundation.h>
#import "ConnectionWrapper.h"

#import "KGOFacebookService.h"
#import "KGOTwitterService.h"
#import "KGOFoursquareService.h"

extern NSString * const KGOSocialMediaTypeFacebook;
extern NSString * const KGOSocialMediaTypeTwitter;
extern NSString * const KGOSocialMediaTypeEmail;
extern NSString * const KGOSocialMediaTypeBitly;
extern NSString * const KGOSocialMediaTypeFoursquare;

// defined in KGOTwitterService.m
extern NSString * const TwitterDidLoginNotification;
extern NSString * const TwitterDidLogoutNotification;

// defined in KGOFacebookService.m
extern NSString * const FacebookDidLoginNotification;
extern NSString * const FacebookDidLogoutNotification;

// defined in KGOFoursquareService.m
extern NSString * const FoursquareDidLoginNotification;
extern NSString * const FoursquareDidLogoutNotification;


@protocol KGOSocialMediaService;
@protocol BitlyWrapperDelegate;

@interface KGOSocialMediaController : NSObject <UIActionSheetDelegate,
ConnectionWrapperDelegate> {
	
	NSDictionary *_appConfig; // from config plist
	
	ConnectionWrapper *_bitlyConnection;
    
    NSMutableDictionary *_startedServices;
}

@property (nonatomic, assign) id<BitlyWrapperDelegate> bitlyDelegate;

+ (KGOSocialMediaController *)sharedController;

- (id<KGOSocialMediaService>)serviceWithType:(NSString *)type;

+ (KGOFacebookService *)facebookService;
+ (KGOTwitterService *)twitterService;
+ (KGOFoursquareService *)foursquareService;

// should only be called by the id<KGOSocialMediaService> object.
- (void)removeServiceWithType:(NSString *)type;

- (void)addOptions:(NSArray *)options forSetting:(NSString *)setting forMediaType:(NSString *)mediaType;

#pragma mark Capabilities

- (NSArray *)allSupportedSharingTypes;

- (BOOL)supportsSharing;
- (BOOL)supportsFacebookSharing;
- (BOOL)supportsTwitterSharing;
- (BOOL)supportsEmailSharing;
- (BOOL)supportsFoursquare;
- (BOOL)supportsBitlyURLShortening;
- (BOOL)supportsService:(NSString *)service;

#pragma mark Queries by service name

+ (NSString *)localizedNameForService:(NSString *)service;

#pragma mark bit.ly

- (void)getBitlyURLForLongURL:(NSString *)longURL delegate:(id<BitlyWrapperDelegate>)delegate;
- (void)shutdownBitly;

@end


