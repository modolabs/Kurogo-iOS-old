#import <UIKit/UIKit.h>
#import "KGOShareButtonController.h"
#import "KGODetailPager.h"

@class NewsStory;
//@class StoryListViewController;

@protocol NewsControllerDelegate <NSObject>

- (BOOL)canSelectPreviousStory;
- (BOOL)canSelectNextStory;
- (NewsStory *)selectPreviousStory;
- (NewsStory *)selectNextStory;

@end

@interface StoryDetailViewController : UIViewController <UIWebViewDelegate, KGOShareButtonDelegate, KGODetailPagerController, KGODetailPagerDelegate> {
	//StoryListViewController *newsController;
    id<NewsControllerDelegate> newsController;
	
	KGODetailPager *storyPager;
    
    UIWebView *storyView;
	NewsStory *story;
    NSArray *stories;
    
	KGOShareButtonController *shareController;
    NSIndexPath *initialIndexPath;
}

@property (nonatomic, retain) id<NewsControllerDelegate> newsController;
//@property (nonatomic, retain) StoryListViewController *newsController;
@property (nonatomic, retain) UIWebView *storyView;
@property (nonatomic, retain) NSArray *stories;
@property (nonatomic, retain) NewsStory *story; // should be private

- (void) setInitialIndexPath:(NSIndexPath *)initialIndexPath;

@end
