#import "MITModule.h"
#import "JSONAPIRequest.h"

@class PeopleSearchViewController;

@interface PeopleModule : MITModule <JSONAPIDelegate> {
	
	PeopleSearchViewController *viewController;
    JSONAPIRequest *request;

}

@property (nonatomic, retain) PeopleSearchViewController *viewController;
@property (nonatomic, retain) JSONAPIRequest *request;

@end

