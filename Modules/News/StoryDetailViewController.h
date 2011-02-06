#import <UIKit/UIKit.h>
#import "KGOShareButtonController.h"

@class NewsStory;
//@class StoryListViewController;

@protocol NewsControllerDelegate <NSObject>

- (BOOL)canSelectPreviousStory;
- (BOOL)canSelectNextStory;
- (NewsStory *)selectPreviousStory;
- (NewsStory *)selectNextStory;

@end

@interface StoryDetailViewController : UIViewController <UIWebViewDelegate, KGOShareButtonDelegate> {
	//StoryListViewController *newsController;
    id<NewsControllerDelegate> newsController;
    NewsStory *story;
	
	UISegmentedControl *storyPager;
    
    UIWebView *storyView;
	
	KGOShareButtonController *shareController;
}

@property (nonatomic, retain) id<NewsControllerDelegate> newsController;
//@property (nonatomic, retain) StoryListViewController *newsController;
@property (nonatomic, retain) NewsStory *story;
@property (nonatomic, retain) UIWebView *storyView;

- (void)displayStory:(NewsStory *)aStory;

@end
