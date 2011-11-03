#import <UIKit/UIKit.h>

@class KGOScrollingTabstrip;
@protocol KGOSearchDisplayDelegate;

@protocol KGOScrollingTabstripDelegate <NSObject>

- (void)tabstrip:(KGOScrollingTabstrip *)tabstrip clickedButtonAtIndex:(NSUInteger)index;

@optional

- (void)tabstripSearchButtonPressed:(KGOScrollingTabstrip *)tabstrip;
- (void)tabstripBookmarkButtonPressed:(KGOScrollingTabstrip *)tabstrip;

@end

// a stricter version of KGOScrollingTabstripDelegate
// which allows the tabstrip to do the search animation
@protocol KGOScrollingTabstripSearchDelegate <KGOScrollingTabstripDelegate, KGOSearchDisplayDelegate>

- (BOOL)tabstripShouldShowSearchDisplayController:(KGOScrollingTabstrip *)tabstrip;
- (UIViewController *)viewControllerForTabstrip:(KGOScrollingTabstrip *)tabstrip;

@end

@class KGOSearchBar, KGOSearchDisplayController;


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
- (NSInteger)indexOfSelectedButton;
- (NSInteger)bookmarkButtonIndex;

@property (nonatomic) BOOL showsSearchButton;
@property (nonatomic) BOOL showsBookmarkButton;

- (void)addButtonWithTitle:(NSString *)title;
- (void)removeAllRegularButtons;

@property (readonly) NSUInteger numberOfButtons;

- (NSString *)buttonTitleAtIndex:(NSUInteger)index;

@property (nonatomic, assign) id<KGOScrollingTabstripDelegate> delegate;
@property (nonatomic, retain) KGOSearchBar *searchBar;
@property (nonatomic, retain) KGOSearchDisplayController *searchController;

- (void)showSearchBarAnimated:(BOOL)animated;
- (void)hideSearchBarAnimated:(BOOL)animated;

@end

