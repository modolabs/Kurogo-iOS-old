#import "KGOModule.h"
#import "KGORequestManager.h"

extern NSString * const EmergencyContactsPathPageName;

@interface EmergencyModule : KGOModule {
    BOOL noticeFeedExists;
    BOOL contactsFeedExists;
	
}

@property (readonly) BOOL noticeFeedExists;
@property (readonly) BOOL contactsFeedExists;
@end

