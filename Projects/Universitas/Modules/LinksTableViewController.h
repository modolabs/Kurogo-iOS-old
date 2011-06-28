#import <UIKit/UIKit.h>
#import "KGORequestManager.h"
#import "KGOTableViewController.h"



@interface LinksTableViewController : KGOTableViewController <KGORequestDelegate>{
    
    NSArray * linksArray;
    
    NSString * description;
    BOOL displayTypeIsList;
    
    UIView * loadingView;
    UIActivityIndicatorView * loadingIndicator;
    
    UIView * headerView;
    
}

@property (nonatomic, retain) KGORequest *request;
@property (nonatomic, retain) UIView * loadingView;
@property (nonatomic, retain) UIActivityIndicatorView * loadingIndicator;

- (id)initWithModuleTag: (NSString *) moduleTag;
- (void) addLoadingView;
- (void) removeLoadingView;
- (UIView *)viewForTableHeader;

@end
