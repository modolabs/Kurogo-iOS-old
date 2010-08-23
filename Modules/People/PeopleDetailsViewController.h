#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "PersonDetails.h"
#import "JSONAPIRequest.h"
#import "MapSearchResultAnnotation.h"

@interface PeopleDetailsViewController : UITableViewController
	<ABPeoplePickerNavigationControllerDelegate, 
	 ABNewPersonViewControllerDelegate, 
	 ABPersonViewControllerDelegate, 
	 JSONAPIDelegate,
     UIAlertViewDelegate,
	 MFMailComposeViewControllerDelegate> 
{

	PersonDetails *personDetails;
	NSMutableArray *sectionArray;
	NSString *fullname;
    
    // issue a background search for address, which if found enables an action icon to view the map
    ArcGISMapAnnotation *addressSearchAnnotation;
    NSInteger addressSection; // tell the tableView which section to reload if address is found
}

@property (nonatomic, retain) PersonDetails *personDetails;
@property (nonatomic, retain) NSMutableArray *sectionArray;
@property (nonatomic, retain) NSString *fullname;

- (void)mapIconTapped:(NSString *)address;
- (void)phoneIconTapped:(NSString *)phone;
- (void)emailIconTapped:(NSString *)email;

@end

@interface PhoneCallAlertViewDelegate : NSObject<UIAlertViewDelegate> {}
@end