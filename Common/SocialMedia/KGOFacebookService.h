#import <Foundation/Foundation.h>
#import "KGOSocialMediaService.h"
#import "Facebook.h"

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
- (void)shareOnFacebook:(NSString *)attachment prompt:(NSString *)prompt;

@end
