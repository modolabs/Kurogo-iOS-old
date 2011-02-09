#import "KGOModule.h"
#import "JSONAPIRequest.h"

@class CampusMapViewController;

@interface MapModule : KGOModule <JSONAPIDelegate> {

	CampusMapViewController* _campusMapVC;
    JSONAPIRequest *_request;
}

@property (nonatomic, retain) CampusMapViewController* campusMapVC;
@property (nonatomic, retain) JSONAPIRequest *request;

@end
