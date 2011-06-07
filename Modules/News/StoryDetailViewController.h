#import <UIKit/UIKit.h>
#import "KGODetailPager.h"

@class NewsStory;
@class KGOShareButtonController;
@class NewsDataController;
//@class StoryListViewController;

@protocol NewsControllerDelegate <NSObject>

- (BOOL)canSelectPreviousStory;
- (BOOL)canSelectNextStory;
- (NewsStory *)selectPreviousStory;
- (NewsStory *)selectNextStory;

@end

@interface StoryDetailViewController : UIViewController <UIWebViewDelegate, KGODetailPagerController, KGODetailPagerDelegate> {
	//StoryListViewController *newsController;
    id<NewsControllerDelegate> newsController;
	
	KGODetailPager *storyPager;
    
    UIWebView *storyView;
	NewsStory *story;
    NSArray *stories;
    
	KGOShareButtonController *shareController;
    NSIndexPath *initialIndexPath;
    
    BOOL multiplePages;
}

@property (nonatomic, retain) id<NewsControllerDelegate> newsController;
@property (nonatomic, retain) NewsDataController *dataManager;

@property (nonatomic, retain) UIWebView *storyView;
@property (nonatomic, retain) NSArray *stories;
@property (nonatomic, retain) NewsStory *story; // use if you only want to present one story
@property (nonatomic, retain) NewsStory *category; // use only if you want the news home button to back to specific category
@property BOOL multiplePages;

- (void) setInitialIndexPath:(NSIndexPath *)initialIndexPath;

@end
