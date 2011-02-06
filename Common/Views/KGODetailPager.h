#import <UIKit/UIKit.h>


@class KGODetailPager;

@protocol KGODetailPagerDelegate

- (void)pager:(KGODetailPager*)pager showContentForPage:(id)content;

@end


@protocol KGODetailPagerController <NSObject>

- (BOOL)pagerCanShowNextPage:(KGODetailPager *)pager;
- (BOOL)pagerCanShowPreviousPage:(KGODetailPager *)pager;
- (id)contentForNextPage:(KGODetailPager *)pager;
- (id)contentForPreviousPage:(KGODetailPager *)pager;

@end


@interface KGODetailPager : UISegmentedControl {
    
    //id<KGODetailPagerDelegate> _pagerDelegate;

}

@property (nonatomic, assign) id<KGODetailPagerDelegate> delegate;
@property (nonatomic, assign) id<KGODetailPagerController> controller;

@end
