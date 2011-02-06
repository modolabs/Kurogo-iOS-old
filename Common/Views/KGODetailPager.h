#import <UIKit/UIKit.h>

@class KGODetailPager;
@protocol KGOSearchResult;

@protocol KGODetailPagerDelegate

- (void)pager:(KGODetailPager*)pager showContentForPage:(id<KGOSearchResult>)content;

@end


@protocol KGODetailPagerController <NSObject>

- (BOOL)pagerCanShowNextPage:(KGODetailPager *)pager;
- (BOOL)pagerCanShowPreviousPage:(KGODetailPager *)pager;
- (id)contentForNextPage:(KGODetailPager *)pager;
- (id)contentForPreviousPage:(KGODetailPager *)pager;

@optional

- (NSInteger)numberOfSections:(KGODetailPager *)pager;
- (NSInteger)pager:(KGODetailPager *)pager numberOfPagesInSection:(NSInteger)section;
- (id<KGOSearchResult>)pager:(KGODetailPager *)pager contentForPageAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface KGODetailPager : UISegmentedControl {
    
	id<KGODetailPagerController> _pagerController;
    id<KGODetailPagerDelegate> _pagerDelegate;

	NSIndexPath *_currentIndexPath;
	NSIndexSet *_sections;
	NSIndexPath *_pagesBySection;
}

- (id)initWithPagerController:(id<KGODetailPagerController>)controller delegate:(id<KGODetailPagerDelegate>)delegate;

@property (nonatomic, retain) NSIndexPath *currentIndexPath;

@property (nonatomic, readonly) id<KGODetailPagerDelegate> delegate;
@property (nonatomic, readonly) id<KGODetailPagerController> controller;

@end
