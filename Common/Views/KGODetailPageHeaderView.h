#import <UIKit/UIKit.h>

@class KGODetailPageHeaderView;

@protocol KGODetailPageHeaderDelegate <NSObject>

@optional

- (void)headerViewFrameDidChange:(KGODetailPageHeaderView *)headerView;
- (void)headerView:(KGODetailPageHeaderView *)headerView shareButtonPressed:(id)sender;

@end

@protocol KGODetailPageCalendarButtonDelegate <NSObject>

@optional

- (void) calendarButtonPressed: (id) sender;

@end


@protocol KGOSearchResult;

@interface KGODetailPageHeaderView : UIView {
    
    UIButton *_bookmarkButton;
    UIButton *_shareButton;
    UIButton *_calendarButton;
    
    BOOL _showsShareButton;
    BOOL _showsBookmarkButton;
    BOOL _showsCalendarButton;
    
    UILabel *_titleLabel;
    UILabel *_subtitleLabel;
    
    id<KGOSearchResult> _detailItem;
}

@property(nonatomic, assign) id<KGODetailPageHeaderDelegate> delegate;
@property(nonatomic, retain) id<KGOSearchResult> detailItem;
@property(nonatomic) BOOL showsShareButton;
@property(nonatomic) BOOL showsBookmarkButton;
@property(nonatomic) BOOL showsCalendarButton;
@property(nonatomic, readonly) UILabel *titleLabel;
@property(nonatomic, readonly) UILabel *subtitleLabel;

- (void)setupBookmarkButtonImages;
- (void)layoutBookmarkButton;
- (void)setupCalendarButtonImages;
- (void)layoutCalendarButton;
- (void)layoutShareButton;
- (void)hideShareButton;
- (void)hideBookmarkButton;
- (void)hideCalendarButton;
- (void)toggleBookmark:(id)sender;

- (CGFloat)headerWidthWithButtons;

@end
