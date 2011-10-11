#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"
#import "KGOSearchDisplayController.h"
#import "KGODetailPager.h"
#import "PeopleDataManager.h"

@class PeopleModule;
@class PersonContactGroup;

@interface PeopleGroupContactViewController : KGOTableViewController <PeopleDataDelegate> {

    NSArray *_allContacts;
}

@property (nonatomic, retain) PeopleDataManager *dataManager;
@property (nonatomic, retain) PersonContactGroup *contactGroup;
@property (nonatomic, assign) PeopleModule *module; 
@property (nonatomic, retain) NSArray *allContacts;

@end
