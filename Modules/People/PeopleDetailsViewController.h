#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "PersonDetails.h"
#import "JSONAPIRequest.h"

@interface PeopleDetailsViewController : UITableViewController 
	<ABPeoplePickerNavigationControllerDelegate, 
	 ABNewPersonViewControllerDelegate, 
	 ABPersonViewControllerDelegate, 
	 JSONAPIDelegate,
	 //UIAlertViewDelegate, 
	 MFMailComposeViewControllerDelegate> 
{

	PersonDetails *personDetails;
	NSMutableArray *sectionArray;
	NSString *fullname;
}

@property (nonatomic, retain) PersonDetails *personDetails;
@property (nonatomic, retain) NSMutableArray *sectionArray;
@property (nonatomic, retain) NSString *fullname;

- (void)mapIconTapped:(NSString *)address;
- (void)phoneIconTapped:(NSString *)phone;
- (void)emailIconTapped:(NSString *)email;

@end

