#import "KGOModule.h"
#import "KGORequestManager.h"
#import "VideoDataManager.h"

@interface VideoModule : KGOModule {

}

@property (nonatomic, retain) VideoDataManager *dataManager;
//@property (nonatomic, retain) NSArray *currentSearchResults;
@property (nonatomic, retain) NSString *searchSection;

@end
