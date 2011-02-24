#import "KGOModule.h"
#import "JSONAPIRequest.h"
#import "KGOSearchDisplayController.h"

extern NSString * const MapTypePreference;
extern NSString * const MapTypePreferenceChanged;

@interface MapModule : KGOModule <JSONAPIDelegate> {

    JSONAPIRequest *_request;
}

@property (nonatomic, retain) JSONAPIRequest *request;

@end
