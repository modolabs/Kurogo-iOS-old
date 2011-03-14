#import <UIKit/UIKit.h>
#import "FacebookMediaViewController.h"
#import "IconGrid.h"
#import "MITThumbnailView.h"
#import "KGOSocialMediaController+FacebookAPI.h"

@class FacebookPhoto;

@interface FacebookPhotosViewController : FacebookMediaViewController <MITThumbnailDelegate, IconGridDelegate,
UINavigationControllerDelegate, UIImagePickerControllerDelegate, FacebookUploadDelegate> {
    
    // TODO: make the set track what photos have been displayed in the grid
    IconGrid *_iconGrid;
    NSMutableArray *_icons;
    NSMutableDictionary *_photosByID;
    NSMutableDictionary *_photosByThumbSrc;
}

- (void)didReceivePhoto:(id)result;
- (void)didReceivePhotoList:(id)result;
- (void)displayPhoto:(FacebookPhoto *)photo;
- (void)loadThumbnailsFromCache;

@end

@interface FacebookThumbnail : UIControl {
    UILabel *_label;
    MITThumbnailView *_thumbnail;
    CGFloat _rotationAngle;
    FacebookPhoto *_photo;
}

@property (nonatomic) CGFloat rotationAngle;
@property (nonatomic, retain) FacebookPhoto *photo;

@end