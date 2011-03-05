#import "KGOModule.h"
#import "KGORequestManager.h"
#import "KGOSearchDisplayController.h"

extern NSString * const MapTypePreference;
extern NSString * const MapTypePreferenceChanged;

@interface MapModule : KGOModule <KGORequestDelegate> {

}

@property (nonatomic, retain) KGORequest *request;

@end
