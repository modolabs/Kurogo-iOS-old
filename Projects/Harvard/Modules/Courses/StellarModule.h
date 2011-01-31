#import "MITModule.h"
#import "JSONAPIRequest.h"

@class StellarMainTableController;

@interface StellarModule : MITModule <JSONAPIDelegate> {

	StellarMainTableController *mainController;
    JSONAPIRequest *request;
}

@property (nonatomic, retain) StellarMainTableController *mainController;
@property (nonatomic, retain) JSONAPIRequest *request;

@end

