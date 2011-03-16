#import "KGOSocialMediaController.h"

@class FacebookPost, FacebookParentPost, FacebookUser;

@protocol FacebookPhotoUploadDelegate <NSObject>

- (void)didUploadPhoto:(id)result;

@end

@protocol FacebookUploadDelegate <NSObject>

- (void)uploadDidComplete:(FacebookPost *)result;
//- (void)uploadDidFail:(NSDictionary *)params;

@end

@interface KGOSocialMediaController (FacebookAPI)

- (BOOL)requestFacebookGraphPath:(NSString *)graphPath receiver:(id)receiver callback:(SEL)callback;
- (BOOL)requestFacebookFQL:(NSString *)query receiver:(id)receiver callback:(SEL)callback;

// TODO: as with other POST methods, have these follow the upload delegate convention
- (BOOL)likeFacebookPost:(FacebookParentPost *)post receiver:(id)receiver callback:(SEL)callback;
- (BOOL)unlikeFacebookPost:(FacebookParentPost *)post receiver:(id)receiver callback:(SEL)callback;

//- (BOOL)addComment:(NSString *)comment toFacebookPost:(FacebookParentPost *)post receiver:(id)receiver callback:(SEL)callback;

- (BOOL)addComment:(NSString *)comment toFacebookPost:(FacebookParentPost *)post delegate:(id<FacebookUploadDelegate>)delegate;
- (BOOL)uploadPhoto:(UIImage *)photo
  toFacebookProfile:(NSString *)graphPath
            message:(NSString *)caption
           delegate:(id<FacebookUploadDelegate>)delegate;


- (void)disconnectFacebookRequests:(id)receiver;

- (FacebookUser *)currentFacebookUser;

@end
