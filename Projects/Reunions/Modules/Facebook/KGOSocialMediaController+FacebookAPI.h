#import "KGOSocialMediaController.h"

@class FacebookParentPost, FacebookUser;

@interface KGOSocialMediaController (FacebookAPI)

- (FBRequest *)requestFacebookGraphPath:(NSString *)graphPath receiver:(id)receiver callback:(SEL)callback;
- (FBRequest *)requestFacebookFQL:(NSString *)query receiver:(id)receiver callback:(SEL)callback;
- (FBRequest *)likeFacebookPost:(FacebookParentPost *)post receiver:(id)receiver callback:(SEL)callback;
- (FBRequest *)unlikeFacebookPost:(FacebookParentPost *)post receiver:(id)receiver callback:(SEL)callback;
- (FBRequest *)addComment:(NSString *)comment toFacebookPost:(FacebookParentPost *)post receiver:(id)receiver callback:(SEL)callback;

- (void)disconnectFacebookRequests:(id)receiver;

- (FacebookUser *)currentFacebookUser;

@end
