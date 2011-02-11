#import <UIKit/UIKit.h>

@class KGOScrollingTabstrip;

@protocol KGOScrollingTabstripDelegate

- (void)tabstrip:(KGOScrollingTabstrip *)tabstrip clickedButtonAtIndex:(NSUInteger)index;

@end


@interface KGOScrollingTabstrip : UIView <UIScrollViewDelegate>
{
    UIView *_contentView;
    UIScrollView *_scrollView;
    UIImageView *_backgroundImageView;
    
    UIButton *_leftScrollButton;
    UIButton *_rightScrollButton;
    
    NSMutableArray *_buttons;
    UIButton *_pressedButton;
    
    UIButton *_searchButton;
    UIButton *_bookmarkButton;
}

- (id)initWithFrame:(CGRect)frame delegate:(id<KGOScrollingTabstripDelegate>)delegate buttonTitles:(NSString *)title, ...;

- (void)selectButtonAtIndex:(NSUInteger)index;

@property (nonatomic) BOOL showsSearchButton;
@property (nonatomic) BOOL showsBookmarkButton;

- (void)addButtonWithTitle:(NSString *)title;

@property (readonly) NSUInteger numberOfButtons;

- (NSInteger)searchButtonIndex;
- (NSInteger)bookmarkButtonIndex;
- (NSString *)buttonTitleAtIndex:(NSUInteger)index;

@property (nonatomic, assign) id<KGOScrollingTabstripDelegate> delegate;

@end

