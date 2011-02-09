#import <Foundation/Foundation.h>
#import "KGOModule.h"
#import "JSONAPIRequest.h"

@interface CalendarModule : KGOModule <JSONAPIDelegate> {

    NSString *searchSpan;
    JSONAPIRequest *request;
	
}

@property (nonatomic, retain) NSString *searchSpan;
@property (nonatomic, retain) JSONAPIRequest *request;

@end

