#import <Foundation/Foundation.h>
#import "KGOSocialMediaService.h"
#import "Facebook.h"

extern NSString * const FacebookTokenKey;
extern NSString * const FacebookTokenPermissions;
extern NSString * const FacebookTokenExpirationSetting;
extern NSString * const FacebookUsernameKey;

@interface KGOFacebookService : NSObject <KGOSocialMediaService, 
FBSessionDelegate, FBDialogDelegate, FBRequestDelegate> {

    NSString *_appID;
    
    // facebook objects manipulated directly by the methods in this file.
	Facebook *_facebook;
    NSInteger _facebookStartupCount;
    
    // optional facebook objects - used by methods in (FacebookAPI) category.
    NSMutableArray *_fbRequestQueue;
    NSMutableArray *_fbRequestIdentifiers;
    NSMutableArray *_fbUploadQueue; // metadata of pending FacebookPost objects
    NSMutableArray *_fbUploadData;
    
    NSMutableDictionary *_apiSettings;
}

- (void)parseCallbackURL:(NSURL *)url;
- (void)shareOnFacebookWithTitle:(NSString *)title url:(NSString *)url body:(NSString *)body;

@end
