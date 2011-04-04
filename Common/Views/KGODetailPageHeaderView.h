#import <UIKit/UIKit.h>

@class KGODetailPageHeaderView;

@protocol KGODetailPageHeaderDelegate <NSObject>

@optional

- (void)headerViewFrameDidChange:(KGODetailPageHeaderView *)headerView;
- (void)headerView:(KGODetailPageHeaderView *)headerView shareButtonPressed:(id)sender;

@end


@protocol KGOSearchResult;

@interface KGODetailPageHeaderView : UIView {
    
    UIButton *_bookmarkButton;
    UIButton *_shareButton;
    
    BOOL _showsShareButton;
    BOOL _showsBookmarkButton;
    
    UILabel *_titleLabel;
    UILabel *_subtitleLabel;
    
    id<KGOSearchResult> _detailItem;
}

@property(nonatomic, assign) id<KGODetailPageHeaderDelegate> delegate;
@property(nonatomic, retain) id<KGOSearchResult> detailItem;
@property(nonatomic) BOOL showsShareButton;
@property(nonatomic) BOOL showsBookmarkButton;
@property(nonatomic, readonly) UILabel *titleLabel;
@property(nonatomic, readonly) UILabel *subtitleLabel;

- (void)layoutBookmarkButton;
- (void)layoutShareButton;
- (void)hideShareButton;
- (void)hideBookmarkButton;

@end
