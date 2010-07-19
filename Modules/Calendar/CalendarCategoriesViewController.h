#import <UIKit/UIKit.h>
#import "JSONAPIRequest.h"

@interface CalendarCategoriesViewController : UITableViewController <JSONAPIDelegate> {

	NSArray *categories;
	
}

@property (nonatomic, retain) NSArray *categories;

@end
