#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"
#import "EmergencyModule.h"

@interface EmergencyContactsViewController : KGOTableViewController {
    EmergencyModule *_module;
    NSArray *_allContacts;
}

@property (nonatomic, retain) EmergencyModule *module;
@property (nonatomic, retain) NSArray *allContacts;

@end
