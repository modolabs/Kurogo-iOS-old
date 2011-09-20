#import <UIKit/UIKit.h>
#import "Video.h"
#import <MediaPlayer/MediaPlayer.h>
#import "VideoDataManager.h"
#import "KGOShareButtonController.h"
//#import "VideoDetailHeaderView.h"
#import "KGODetailPageHeaderView.h"


@interface VideoDetailViewController : UIViewController <MITThumbnailDelegate,
KGODetailPageHeaderDelegate> {
    KGOShareButtonController *_shareController;    
    KGODetailPageHeaderView *_headerView;
    //UIView *bookmarkSharingView;

}

@property (nonatomic, retain) Video *video;
@property (nonatomic, retain) MPMoviePlayerController *player;
@property (nonatomic, retain) VideoDataManager *dataManager;
@property (nonatomic, retain) NSString *section;
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) KGODetailPageHeaderView *headerView;

- (id)initWithVideo:(Video *)aVideo andSection:(NSString *)videoSection;
- (void)requestVideoForDetailView;
- (void) setDescription;
- (UIView *)viewForTableHeader;

@end
