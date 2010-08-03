#import "MITModule.h"

@class CampusMapViewController;

@interface CMModule : MITModule <JSONAPIDelegate> {

	CampusMapViewController* _campusMapVC;
    JSONAPIRequest *_request;
}

@property (nonatomic, retain) CampusMapViewController* campusMapVC;
@property (nonatomic, retain) JSONAPIRequest *request;

@end
