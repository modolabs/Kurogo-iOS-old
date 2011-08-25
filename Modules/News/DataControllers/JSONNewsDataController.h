#import "NewsDataController.h"
#import "KGORequestManager.h"
#import "NewsCategory.h"
#import "NewsStory.h"
#import "NewsImage.h"

@interface JSONNewsDataController : NewsDataController <KGORequestDelegate> {

}

@property (nonatomic, retain) KGORequest *storiesRequest;
@property (nonatomic, retain) NSMutableSet *searchRequests;

@end

