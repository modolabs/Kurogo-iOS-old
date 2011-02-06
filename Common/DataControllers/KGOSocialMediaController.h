#import <Foundation/Foundation.h>
#import "MGTwitterEngine.h"
#import "ConnectionWrapper.h"
#import "Facebook.h"

extern NSString * const KGOSocialMediaTypeFacebook;
extern NSString * const KGOSocialMediaTypeTwitter;
extern NSString * const KGOSocialMediaTypeEmail;
extern NSString * const KGOSocialMediaTypeBitly;

@protocol TwitterWrapperDelegate <NSObject>

- (void)twitterDidLogin;
- (void)promptForTwitterLogin;
- (void)twitterFailedToLogin;
- (void)twitterDidLogout;

- (void)twitterRequestSucceeded:(NSString *)connectionIdentifier;

@optional

- (void)twitterRequestFailed:(NSString *)connectionIdentifier withError:(NSError *)error;

@end


@protocol FacebookWrapperDelegate

- (void)facebookDidLogin;
- (void)facebookFailedToLogin;
- (void)facebookDidLogout;

@end



@protocol BitlyWrapperDelegate <NSObject>

- (void)didGetBitlyURL:(NSString *)url;

@optional

- (void)failedToGetBitlyURL;

@end


@interface KGOSocialMediaController : NSObject <UIActionSheetDelegate,
MGTwitterEngineDelegate, ConnectionWrapperDelegate,
FBSessionDelegate, FBDialogDelegate, FBRequestDelegate> {
	
	NSDictionary *_preferences;
	
	MGTwitterEngine *_twitterEngine;
	NSString *_twitterUsername;
	
	ConnectionWrapper *_bitlyConnection;

	Facebook *_facebook;
}

@property (nonatomic, assign) id<TwitterWrapperDelegate> twitterDelegate;
@property (nonatomic, assign) id<BitlyWrapperDelegate> bitlyDelegate;
@property (nonatomic, assign) id<FacebookWrapperDelegate> facebookDelegate;
@property (nonatomic, retain) NSString *twitterUsername;

+ (KGOSocialMediaController *)sharedController;

#pragma mark Capabilities

- (NSArray *)allSupportedSharingTypes;

- (BOOL)supportsSharing;
- (BOOL)supportsFacebookSharing;
- (BOOL)supportsTwitterSharing;
- (BOOL)supportsEmailSharing;

#pragma mark Twitter

- (void)startupTwitter;
- (void)shutdownTwitter;

- (void)loginTwitterWithDelegate:(id<TwitterWrapperDelegate>)delegate;
- (void)loginTwitterWithUsername:(NSString *)username password:(NSString *)password;
- (void)logoutTwitter;

- (void)postToTwitter:(NSString *)text;

#pragma mark bit.ly

- (void)getBitlyURLForLongURL:(NSString *)longURL delegate:(id<BitlyWrapperDelegate>)delegate;
- (void)shutdownBitly;

#pragma mark Facebook

- (void)startupFacebook;
- (void)shutdownFacebook;

- (void)shareOnFacebook:(NSString *)attachment prompt:(NSString *)prompt;

- (void)loginFacebookWithDelegate:(id<FacebookWrapperDelegate>)delegate;
- (void)logoutFacebook;

@end
