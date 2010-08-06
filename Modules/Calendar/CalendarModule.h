#import <Foundation/Foundation.h>
#import "MITModule.h"
#import "JSONAPIRequest.h"

@class CalendarEventsViewController;

@interface CalendarModule : MITModule <JSONAPIDelegate> {

	CalendarEventsViewController *calendarVC;
    NSString *searchSpan;
    JSONAPIRequest *request;
	
}

@property (nonatomic, retain) CalendarEventsViewController *calendarVC;
@property (nonatomic, retain) NSString *searchSpan;
@property (nonatomic, retain) JSONAPIRequest *request;

@end

