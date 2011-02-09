#import "KGOModule.h"
#import "JSONAPIRequest.h"

@class PeopleSearchViewController;

@interface PeopleModule : KGOModule <JSONAPIDelegate> {
	
    JSONAPIRequest *request;
}

@property (nonatomic, retain) JSONAPIRequest *request;

@end

