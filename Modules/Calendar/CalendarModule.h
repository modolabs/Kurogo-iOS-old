#import <Foundation/Foundation.h>
#import "KGOModule.h"
#import "JSONAPIRequest.h"

@interface CalendarModule : KGOModule <JSONAPIDelegate> {

    JSONAPIRequest *request;
	
}

@property (nonatomic, retain) JSONAPIRequest *request;

@end

