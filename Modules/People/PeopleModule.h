#import "KGOModule.h"
#import "JSONAPIRequest.h"
#import "KGORequestManager.h"

@interface PeopleModule : KGOModule <KGORequestDelegate> {
	
}

@property (nonatomic, retain) KGORequest *request;

@end

