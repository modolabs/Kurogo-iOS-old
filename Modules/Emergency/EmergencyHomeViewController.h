#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"
#import "EmergencyNotice.h"
#import "EmergencyModule.h"


enum EmergencyLoadingStatus {
    Loading,
    Loaded,
    Failed,
};

@interface EmergencyHomeViewController : KGOTableViewController <UIWebViewDelegate> {
    NSNumber *_contentDivHeight;
    EmergencyModule *_module;
    EmergencyNotice *_notice;
    UIWebView *_infoWebView;
    enum EmergencyLoadingStatus loadingStatus;
    
    NSArray *_primaryContacts;
    BOOL _hasMoreContact;
}

@property (nonatomic, retain) NSNumber *contentDivHeight;
@property (nonatomic, retain) EmergencyModule *module;
@property (nonatomic, retain) EmergencyNotice *notice;
@property (nonatomic, retain) UIWebView *infoWebView;

@property (nonatomic, retain) NSArray *primaryContacts;

@end
