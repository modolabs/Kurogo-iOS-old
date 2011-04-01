#import <Foundation/Foundation.h>
#import "KGOModule.h"
#import "KGORequestManager.h"

@class CalendarDataManager;

@interface CalendarModule : KGOModule <KGORequestDelegate> {
	
}

@property (nonatomic, retain) KGORequest *request;
@property (nonatomic, retain) CalendarDataManager *dataManager;

- (NSString *)defaultCalendar;

@end

