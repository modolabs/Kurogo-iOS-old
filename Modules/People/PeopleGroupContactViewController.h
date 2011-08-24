#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"
#import "KGOSearchDisplayController.h"
#import "KGODetailPager.h"
#import "KGORequestManager.h"

@class PeopleModule;

@interface PeopleGroupContactViewController : KGOTableViewController <KGORequestDelegate>{

    NSArray *_allContacts;
    KGORequest *_request;
    NSString *_group; 
}

@property (nonatomic, assign) PeopleModule *module; 
@property (nonatomic, retain) NSArray *allContacts;


- (id)initWithGroup:(NSString *)group;
@end
