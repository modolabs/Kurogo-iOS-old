#import <UIKit/UIKit.h>
#import "KGOModule.h"
#import "IconGrid.h"
#import "KGORequestManager.h"
#import "KGOTableViewController.h"

typedef enum {
    LinksDisplayTypeList,
    LinksDisplayTypeSpringboard
} LinksDisplayType;

@interface LinksTableViewController : KGOTableViewController <KGORequestDelegate, IconGridDelegate>{
    
    ModuleTag *moduleTag;
    
    NSArray * linksArray;
    
    NSString * description;
    
    LinksDisplayType displayType;
    
    UIView * loadingView;
    UIActivityIndicatorView * loadingIndicator;
    
    UIView * headerView;
    
    // views for SpringBoard
    IconGrid *iconGrid;
    UIScrollView *scrollView;
    UILabel *descriptionLabel;
    
}

@property (nonatomic, retain) KGORequest *request;
@property (nonatomic, retain) UIView * loadingView;
@property (nonatomic, retain) UIActivityIndicatorView * loadingIndicator;

- (id)initWithModuleTag: (ModuleTag *) moduleTag;
- (void) addLoadingView;
- (void) removeLoadingView;
- (UIView *)viewForTableHeader;

@end
