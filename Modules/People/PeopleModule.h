#import "KGOModule.h"
#import "KGORequestManager.h"

@interface PeopleModule : KGOModule <KGORequestDelegate> {
	
}

@property (nonatomic, retain) KGORequest *request;

@end

