#import "FacebookMediaDetailViewController.h"

@class FacebookVideo;

@interface FacebookVideoDetailViewController : FacebookMediaDetailViewController {
    
    MITThumbnailView *_thumbnail;
}

@property(nonatomic, retain) FacebookVideo *video;

- (void)loadVideosFromCache;

@end
