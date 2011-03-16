#import "FacebookMediaDetailViewController.h"

@class FacebookPhoto;

@interface FacebookPhotoDetailViewController : FacebookMediaDetailViewController {
    
    MITThumbnailView *_thumbnail;
}

@property(nonatomic, retain) FacebookPhoto *photo;


@end