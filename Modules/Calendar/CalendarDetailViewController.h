#import <UIKit/UIKit.h>
#import "JSONAPIRequest.h"
#import "CalendarConstants.h"
#import "ShareDetailViewController.h"
#import "MIT_MobileAppDelegate.h"
#import <MessageUI/MFMailComposeViewController.h>;

@class MITCalendarEvent;

@interface CalendarDetailViewController : ShareDetailViewController <UITableViewDelegate, UITableViewDataSource, JSONAPIDelegate, ShareItemDelegate, UIWebViewDelegate, MFMailComposeViewControllerDelegate> {
	
    BOOL isRegularEvent;
    
	MITCalendarEvent *event;
	CalendarEventListType* rowTypes;
	NSInteger numRows;
	
	UITableView *_tableView;
	UIButton *shareButton;
	
    NSInteger descriptionHeight;
	NSMutableString *descriptionString;
	
    CGFloat categoriesHeight;
	NSMutableString *categoriesString;

	// list of events to scroll through for previous/next buttons
	NSArray *events;
}

@property (nonatomic, assign) MITCalendarEvent *event;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, assign) NSArray *events;

- (void)reloadEvent;
- (void)setupHeader;
- (void)setupShareButton;
- (void)requestEventDetails;
- (void)showNextEvent:(id)sender;

- (NSString *)htmlStringFromString:(NSString *)source;
-(void)emailTo:(NSString*)subject body:(NSString *)emailBody email:(NSString *)emailAddress;

@end

