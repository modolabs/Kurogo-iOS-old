#import <UIKit/UIKit.h>
#import "CalendarConstants.h"
#import "KGOShareButtonController.h"
#import "KGOAppDelegate.h"
#import "KGOShareButtonController.h"
#import "KGOTableViewController.h"

@class KGOEvent;

@interface CalendarDetailViewController : KGOTableViewController <KGOShareButtonDelegate, UIWebViewDelegate> {
	
    BOOL isRegularEvent;
    
	KGOEvent *event;
	CalendarEventListType* rowTypes;
	NSInteger numRows;
	
	UIButton *shareButton;
	
    NSInteger descriptionHeight;
	NSMutableString *descriptionString;
	
    CGFloat categoriesHeight;
	NSMutableString *categoriesString;

	// list of events to scroll through for previous/next buttons
	NSArray *events;
	
	KGOShareButtonController *shareController;
}

@property (nonatomic, assign) KGOEvent *event;
@property (nonatomic, assign) NSArray *events;

- (void)reloadEvent;
- (void)setupHeader;
- (void)setupShareButton;
- (void)showNextEvent:(id)sender;

@end

