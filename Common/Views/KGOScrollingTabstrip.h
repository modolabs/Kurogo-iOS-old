#import <UIKit/UIKit.h>

@class KGOScrollingTabstrip;

@protocol KGOScrollingTabstripDelegate <NSObject>

- (void)tabstrip:(KGOScrollingTabstrip *)tabstrip clickedButtonAtIndex:(NSUInteger)index;

@optional

- (void)tabstripSearchButtonPressed:(KGOScrollingTabstrip *)tabstrip;
- (void)tabstripBookmarkButtonPressed:(KGOScrollingTabstrip *)tabstrip;

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

- (NSString *)buttonTitleAtIndex:(NSUInteger)index;

@property (nonatomic, assign) id<KGOScrollingTabstripDelegate> delegate;

@end

