#import "KGOModule.h"
//#import "KGORequestManager.h"
#import "KGOSearchDisplayController.h"
#import "MapDataManager.h"

extern NSString * const MapTypePreference;
extern NSString * const MapTypePreferenceChanged;

@interface MapModule : KGOModule //<KGORequestDelegate> {
{

}

@property (nonatomic, retain) MapDataManager *dataManager;
//@property (nonatomic, retain) KGORequest *request;

//- (KGORequest *)subcategoriesRequestForCategory:(NSString *)category delegate:(id<KGORequestDelegate>)delegate;

@end
