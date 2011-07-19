#import <UIKit/UIKit.h>
#import "KGOModule.h"
#import "KGORequestManager.h"
#import "KGOTableViewController.h"

typedef enum {
    LinksDisplayTypeList,
    LinksDisplayTypeSpringboard
} LinksDisplayType;

@interface LinksTableViewController : KGOTableViewController <KGORequestDelegate>{
    
    NSString *moduleTag;
    
    NSArray * linksArray;
    
    NSString * description;
    
    LinksDisplayType displayType;
    
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
