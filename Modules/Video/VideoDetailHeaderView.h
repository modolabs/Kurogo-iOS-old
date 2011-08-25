#import <UIKit/UIKit.h>
#import "Video.h"

@class VideoDetailHeaderView;

@protocol VideoDetailHeaderDelegate <NSObject>

@optional

- (void)headerViewFrameDidChange:(VideoDetailHeaderView *)headerView;
- (void)headerView:(VideoDetailHeaderView *)headerView shareButtonPressed:(id)sender;


@end


//@protocol DetailVideo;

@interface VideoDetailHeaderView : UIView {
    
    UIButton *_bookmarkButton;
    UIButton *_shareButton;
    
    BOOL _showsShareButton;
    BOOL _showsBookmarkButton;
    
    //id<DetailVideo> _detailItem;
}

@property(nonatomic, assign) id<VideoDetailHeaderDelegate> delegate;
//@property(nonatomic, retain) id<DetailVideo> detailItem;
@property(nonatomic) BOOL showsShareButton;
@property(nonatomic) BOOL showsBookmarkButton;
@property (nonatomic, retain) Video *video;

- (void)setupBookmarkButtonImages;
- (void)layoutBookmarkButton;
- (void)layoutShareButton;
- (void)hideShareButton;
- (void)hideBookmarkButton;
- (void)toggleBookmark:(id)sender;

- (CGFloat)headerWidthWithButtons;

@end
