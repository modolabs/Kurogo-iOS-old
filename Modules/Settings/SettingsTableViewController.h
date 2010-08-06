#import <UIKit/UIKit.h>
#import "JSONAPIRequest.h"
#import "MITModule.h"

@interface SettingsTableViewController : UITableViewController <JSONAPIDelegate> {

    NSArray *notifications;
	NSMutableDictionary *apiRequests;
	
}

- (void)reloadSettings;

@property (nonatomic, retain) NSArray *notifications;
@property (nonatomic, retain) NSMutableDictionary *apiRequests;

@end
