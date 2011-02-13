#import "KGOModule.h"
#import "JSONAPIRequest.h"
#import "KGOSearchDisplayController.h"

@interface MapModule : KGOModule <JSONAPIDelegate> {

    JSONAPIRequest *_request;
}

@property (nonatomic, retain) JSONAPIRequest *request;

@end
