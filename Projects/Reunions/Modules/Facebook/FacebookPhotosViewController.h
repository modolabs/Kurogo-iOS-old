#import <UIKit/UIKit.h>
#import "KGOSocialMediaController.h"
#import "Facebook.h"

// still deciding how FB wrapper work should be allocated
// between KGOSocialMediaController and this class.
// since this is a facebook module it would be fine to put as much fb stuff in here as we want
@interface FacebookPhotosViewController : UIViewController <FacebookWrapperDelegate,
FBRequestDelegate> {

}

@end
