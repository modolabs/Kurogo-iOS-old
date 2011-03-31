#import <UIKit/UIKit.h>

@class KGODetailPager;
@protocol KGOSearchResult;

@protocol KGODetailPagerDelegate

- (void)pager:(KGODetailPager*)pager showContentForPage:(id<KGOSearchResult>)content;

@end


@protocol KGODetailPagerController <NSObject>

- (NSInteger)pager:(KGODetailPager *)pager numberOfPagesInSection:(NSInteger)section;
- (id<KGOSearchResult>)pager:(KGODetailPager *)pager contentForPageAtIndexPath:(NSIndexPath *)indexPath;

@optional

// TODO: rename this to numberOfPagerSections to be more specific
- (NSInteger)numberOfSections:(KGODetailPager *)pager;

@end

@interface KGODetailPager : UISegmentedControl {
    
	id<KGODetailPagerController> _pagerController;
    id<KGODetailPagerDelegate> _pagerDelegate;

	NSIndexPath *_currentIndexPath;
	NSIndexSet *_sections;
	NSIndexPath *_pagesBySection;
}

- (id)initWithPagerController:(id<KGODetailPagerController>)controller delegate:(id<KGODetailPagerDelegate>)delegate;

- (void)selectPageAtSection:(NSInteger)section row:(NSInteger)row;

@property (nonatomic, readonly) NSIndexPath *currentIndexPath;

@property (nonatomic, readonly) id<KGODetailPagerDelegate> delegate;
@property (nonatomic, readonly) id<KGODetailPagerController> controller;



@end
