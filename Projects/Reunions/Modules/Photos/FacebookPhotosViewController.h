#import <UIKit/UIKit.h>
#import "KGOSocialMediaController.h"
#import "Facebook.h"
#import "FacebookMediaViewController.h"

@class IconGrid;

// still deciding how FB wrapper work should be allocated
// between KGOSocialMediaController and this class.
// since this is a facebook module it would be fine to put as much fb stuff in here as we want
@interface FacebookPhotosViewController : FacebookMediaViewController {
    
    NSMutableArray *_fbRequestQueue;
    //FBRequest *_groupsRequest;
    FBRequest *_photosRequest;
    FBRequest *_feedRequest;

    IconGrid *_iconGrid;
    NSMutableArray *_icons;
    NSMutableSet *_photoIDs;
    
    NSString *_gid;
}

- (void)didReceivePhotos:(id)result;
- (void)didReceivePhotoList:(id)result;

@end
