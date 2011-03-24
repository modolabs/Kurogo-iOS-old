#import <Foundation/Foundation.h>
#import "KGOModule.h"
#import "KGORequestManager.h"

@interface CalendarModule : KGOModule <KGORequestDelegate> {
	
}

@property (nonatomic, retain) KGORequest *request;

- (NSString *)defaultCalendar;

@end

