#import "KGOModule.h"
#import "KGORequestManager.h"
#import "KGOWebViewController.h"

@interface AboutModule : KGOModule <KGORequestDelegate>{

}
@property (nonatomic, retain) KGORequest * aboutRequest;
@property (nonatomic, retain) NSString * webViewTitle;

@end
