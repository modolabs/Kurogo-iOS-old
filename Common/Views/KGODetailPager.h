#import <UIKit/UIKit.h>


@class KGODetailPager;

@protocol KGODetailPagerDelegate <NSObject>

- (BOOL)pagerCanPageUp:(KGODetailPager *)pager;
- (BOOL)pagerCanPageDown:(KGODetailPager *)pager;
- (void)pageUp:(KGODetailPager *)pager;
- (void)pageDown:(KGODetailPager *)pager;

@end


@interface KGODetailPager : UISegmentedControl {
    
    id<KGODetailPagerDelegate> _pagerDelegate;

}

@property (nonatomic, assign) id<KGODetailPagerDelegate> delegate;

@end
